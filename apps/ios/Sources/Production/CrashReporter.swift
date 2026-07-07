import Foundation
import UIKit

@MainActor
final class CrashReporter {
    static let shared = CrashReporter()
    
    private var isActive = false
    
    func start() {
        guard !isActive else { return }
        isActive = true
        
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.report(
                name: exception.name.rawValue,
                reason: exception.reason ?? "Unknown",
                stack: exception.callStackSymbols
            )
        }
        
        // Set up signal handlers for crashes
        signal(SIGABRT) { signal in
            CrashReporter.shared.reportSignal(signal)
        }
        signal(SIGSEGV) { signal in
            CrashReporter.shared.reportSignal(signal)
        }
        signal(SIGBUS) { signal in
            CrashReporter.shared.reportSignal(signal)
        }
        
        print("[Agentbot] Crash reporter started")
    }
    
    func stop() {
        NSSetUncaughtExceptionHandler(nil)
        signal(SIGABRT, SIG_DFL)
        signal(SIGSEGV, SIG_DFL)
        signal(SIGBUS, SIG_DFL)
        isActive = false
    }
    
    private func report(name: String, reason: String, stack: [String]) {
        let info: [String: Any] = [
            "type": "exception",
            "name": name,
            "reason": reason,
            "stack": stack.prefix(20).joined(separator: "\n"),
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "unknown",
            "buildVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "unknown",
            "osVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model,
        ]
        
        sendCrashReport(info)
    }
    
    private func reportSignal(_ signal: Int32) {
        let info: [String: Any] = [
            "type": "signal",
            "signal": signal,
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "unknown",
        ]
        
        sendCrashReport(info)
    }
    
    private func sendCrashReport(_ info: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: info) else { return }
        
        var request = URLRequest(url: URL(string: "https://agentbot-backend.fly.dev/api/crashes")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    func recordError(_ error: Error, context: String? = nil) {
        let info: [String: Any] = [
            "type": "error",
            "error": error.localizedDescription,
            "context": context ?? "",
            "timestamp": Date().timeIntervalSince1970,
        ]
        sendCrashReport(info)
    }
}
