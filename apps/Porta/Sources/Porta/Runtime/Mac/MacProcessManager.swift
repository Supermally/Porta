import Foundation

public final class MacProcessManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacProcessManager()

    @Published public var isGameModeActive: Bool = false
    @Published public var activeSessionPID: pid_t?

    private var activityToken: NSObjectProtocol?

    public init() {}

    public func enterGameMode(reason: String) {
        let token = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled, .latencyCritical],
            reason: reason
        )
        self.activityToken = token
        DispatchQueue.main.async {
            self.isGameModeActive = true
        }
    }

    public func exitGameMode() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            self.activityToken = nil
        }
        DispatchQueue.main.async {
            self.isGameModeActive = false
            self.activeSessionPID = nil
        }
    }

    public func terminateProcessTree(pid: pid_t) {
        // Kill direct process
        kill(pid, SIGTERM)

        // Kill process group
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killTask.arguments = ["-9", "-P", "\(pid)"]
        try? killTask.run()
        killTask.waitUntilExit()

        exitGameMode()
    }
}
