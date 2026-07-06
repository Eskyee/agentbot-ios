import Foundation

final class CrashReporter {
    static let shared = CrashReporter()
    
    func start() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.report(exception: exception)
        }
    }
    
    private func report(exception: NSException) {
        let info: [String: Any] = [
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "stackSymbols": exception.callStackSymbols,
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "unknown",
        ]
        // Send to crash reporting endpoint
        print("[Agentbot] Crash: \(info)")
    }
}