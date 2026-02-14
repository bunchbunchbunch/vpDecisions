import Foundation
import Security

/// Provides certificate pinning for network requests to trusted domains.
/// Protects against MITM attacks on compromised networks.
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    /// SHA-256 hashes of the public keys we trust for Supabase
    /// These are the SPKI (Subject Public Key Info) hashes
    /// To get these, run: openssl s_client -connect api.videopoker.academy:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
    private let pinnedHashes: Set<String> = [
        // Supabase uses Cloudflare - these are Cloudflare's intermediate CA public key hashes
        // You should verify and update these periodically
        // Note: Including multiple hashes allows for certificate rotation
    ]

    /// Domains that require certificate pinning
    private let pinnedDomains: Set<String> = [
        "api.videopoker.academy",
        "ctqefgdvqiaiumtmcjdz.supabase.co",
        "supabase.co"
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host.lowercased() as String?,
              pinnedDomains.contains(where: { host.hasSuffix($0) }) else {
            // Not a pinned domain, use default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If no pins configured, allow connection (fail-open for initial setup)
        // Remove this once pins are configured
        if pinnedHashes.isEmpty {
            debugLog("⚠️ Certificate pinning: No pins configured, allowing connection to \(host)")
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the server trust
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard isValid else {
            debugLog("❌ Certificate pinning: Trust evaluation failed for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain matches our pinned hashes
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            debugLog("❌ Certificate pinning: Failed to get certificate chain for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        var foundMatch = false
        for certificate in certificateChain {
            let publicKeyHash = getPublicKeyHash(for: certificate)
            if let hash = publicKeyHash, pinnedHashes.contains(hash) {
                foundMatch = true
                break
            }
        }

        if foundMatch {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            debugLog("❌ Certificate pinning: No matching pin found for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Extract and hash the public key from a certificate
    private func getPublicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else { return nil }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // Hash the public key data with SHA-256
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(publicKeyData.count), &hash)
        }

        return Data(hash).base64EncodedString()
    }
}

// CommonCrypto bridge for SHA-256
import CommonCrypto

/// Shared URLSession with certificate pinning enabled
enum PinnedURLSession {
    private static let delegate = CertificatePinningDelegate()

    /// URLSession configured with certificate pinning
    static let shared: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }()
}
