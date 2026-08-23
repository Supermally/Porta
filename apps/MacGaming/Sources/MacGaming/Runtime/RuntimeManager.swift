import Foundation
import AppKit

public final class RuntimeManager: ObservableObject, @unchecked Sendable {
    public static let shared = RuntimeManager()

    @Published public var activeSessionGameId: String?
    @Published public var isSessionRunning: Bool = false
    @Published public var lastSessionExitCode: Int32 = 0

    private var activeProcess: Process?
    private var activeActivityToken: NSObjectProtocol?

    public init() {}

    public func locateBestWineRunner() -> String? {
        let runnerPaths = [
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/MacGaming/Runtimes/Wine/Contents/Resources/wine/bin/wine64",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/MacGaming/Runtimes/Wine/Contents/Resources/wine/bin/wine",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/MacGaming/Runner/Wine Staging.app/Contents/Resources/wine/bin/wine64",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wine64",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/CrossOver/bin/wine64",
            "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine"
        ]

        for path in runnerPaths {
            if FileManager.default.fileExists(atPath: path) && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public func launchWindowsExecutable(
        executablePath: String,
        arguments: [String] = [],
        workingDirectory: String? = nil,
        config: RuntimeEnvironmentConfig,
        gameId: String,
        onOutput: @escaping @Sendable (String) -> Void,
        onCompletion: @escaping @Sendable (Int32) -> Void
    ) {
        guard let wineBinary = locateBestWineRunner() else {
            onOutput("❌ No Wine runner discovered. Please install or verify runtimes in Settings.")
            onCompletion(-1)
            return
        }

        let prefixURL = PrefixManager.shared.preparePrefix(for: gameId, config: config)
        let cacheURL = PrefixManager.shared.shaderDiskCacheURL(for: gameId)
        let env = GraphicsTranslationEngine.shared.buildEnvironment(for: config, prefixURL: prefixURL, cacheURL: cacheURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: wineBinary)
        process.arguments = [executablePath] + arguments
        process.environment = env
        if let wd = workingDirectory, !wd.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: wd)
        } else {
            process.currentDirectoryURL = URL(fileURLWithPath: (executablePath as NSString).deletingLastPathComponent)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                onOutput(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        // Assert macOS Game Mode & Latency Critical Priority
        let token = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled, .latencyCritical],
            reason: "Apple Gaming Compatibility Runtime - \(gameId)"
        )
        self.activeActivityToken = token
        self.activeProcess = process

        DispatchQueue.main.async {
            self.activeSessionGameId = gameId
            self.isSessionRunning = true
        }

        process.terminationHandler = { [weak self] proc in
            pipe.fileHandleForReading.readabilityHandler = nil
            ProcessInfo.processInfo.endActivity(token)

            DispatchQueue.main.async {
                self?.isSessionRunning = false
                self?.activeSessionGameId = nil
                self?.lastSessionExitCode = proc.terminationStatus
                self?.activeProcess = nil
                self?.activeActivityToken = nil
                onCompletion(proc.terminationStatus)
            }
        }

        do {
            try process.run()
            onOutput("🟢 Started runtime process [PID: \(process.processIdentifier)] via \(wineBinary)")
        } catch {
            onOutput("❌ Process execution failed: \(error.localizedDescription)")
            onCompletion(-1)
        }
    }

    public func terminateActiveSession() {
        if let proc = activeProcess, proc.isRunning {
            proc.terminate()
        }
    }
}
