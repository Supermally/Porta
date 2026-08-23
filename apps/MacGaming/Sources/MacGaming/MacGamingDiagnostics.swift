import Foundation
import os.log

public enum DiagnosticLayer {
    case process
    case memory
    case graphics
    case filesystem
    case network
}

public class MacGamingDiagnostics {
    public static let shared = MacGamingDiagnostics()
    
    private let logger = Logger(subsystem: "com.macgaming.runtime", category: "Diagnostics")
    
    private init() {}
    
    public func recordEvent(layer: DiagnosticLayer, name: String, metadata: [String: Any]? = nil) {
        var logMessage = "[\(layer)] \(name)"
        if let meta = metadata, !meta.isEmpty {
            logMessage += " | \(meta.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        }
        
        logger.debug("\(logMessage, privacy: .public)")
    }
    
    public func captureCrashDump(pid: pid_t, reason: String) {
        logger.fault("CRITICAL: Process \(pid) crashed. Reason: \(reason)")
        // Shell out to macOS crash reporter or spindump
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/spindump")
        task.arguments = ["\(pid)", "-file", "/tmp/macgaming_crash_\(pid).txt"]
        try? task.run()
    }
}
