import Foundation

/// Debug logging that only outputs in DEBUG builds.
/// Use this instead of print() or NSLog() to prevent logging in production.
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

/// Debug logging with NSLog format (for Objective-C style format strings).
/// Only outputs in DEBUG builds.
@inline(__always)
func debugNSLog(_ format: String, _ args: CVarArg...) {
    #if DEBUG
    withVaList(args) { ptr in
        NSLogv(format, ptr)
    }
    #endif
}
