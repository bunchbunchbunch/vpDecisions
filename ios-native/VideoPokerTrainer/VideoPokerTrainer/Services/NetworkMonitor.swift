import Foundation
import Network

@MainActor
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isOnline = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, wired, unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                self.isOnline = path.status == .satisfied
                self.connectionType = self.getConnectionType(path)

                // Trigger sync when coming back online
                if path.status == .satisfied {
                    await SyncService.shared.syncPendingAttempts()
                }
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        return .unknown
    }

    deinit {
        monitor.cancel()
    }
}
