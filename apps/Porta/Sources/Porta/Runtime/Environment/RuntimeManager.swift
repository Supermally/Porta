import Foundation
import SwiftUI
import AppKit
import Combine

public final class RuntimeManager: ObservableObject, @unchecked Sendable {
    public static let shared = RuntimeManager()

    @Published public var runtimes: [RuntimeItem] = []
    @Published public var defaultRuntimeId: String = "forge_wine10"
    
    // Legacy / Session Tracking
    @Published public var activeSessionGameId: String?
    @Published public var isSessionRunning: Bool = false
    @Published public var lastSessionExitCode: Int32 = 0

    private var activeProcess: Process?
    private var activeActivityToken: NSObjectProtocol?

    public init() {
        detectRuntimes()
    }

    public func detectRuntimes() {
        let fileManager = FileManager.default
        var discovered: [RuntimeItem] = []

        // 1. Primary Forge Compatibility Runtime (Wine 10 + D3DMetal Sikarugir engine)
        let sikarugirWine = fileManager.homeDirectoryForCurrentUser.path + "/Applications/Sikarugir/Steam.app/Contents/SharedSupport/wine/bin/wine"
        let sikarugirServer = fileManager.homeDirectoryForCurrentUser.path + "/Applications/Sikarugir/Steam.app/Contents/SharedSupport/wine/bin/wineserver"
        if fileManager.fileExists(atPath: sikarugirWine) {
            discovered.append(
                RuntimeItem(
                    id: "forge_wine10",
                    name: "Forge Runtime 1.0 (Wine 10 + D3DMetal)",
                    version: "10.0-rev6 (Apple Silicon Native)",
                    architecture: "ARM64 WoW64 Unified",
                    runnerPath: sikarugirWine,
                    serverPath: sikarugirServer,
                    metalSupportLevel: "Apple D3DMetal (DirectX 11/12)",
                    isDefault: true,
                    isHealthy: true
                )
            )
        }

        // 2. Porta / Local Runtime
        let localWine = fileManager.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/Runtimes/Wine/Contents/Resources/wine/bin/wine"
        let localServer = fileManager.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/Runtimes/Wine/Contents/Resources/wine/bin/wineserver"
        if fileManager.fileExists(atPath: localWine) && localWine != sikarugirWine {
            discovered.append(
                RuntimeItem(
                    id: "forge_runtime_local",
                    name: "Forge Local Runtime",
                    version: "10.0 (Local Bundle)",
                    runnerPath: localWine,
                    serverPath: localServer,
                    metalSupportLevel: "DirectX 11 / Metal",
                    isDefault: discovered.isEmpty,
                    isHealthy: true
                )
            )
        }

        // 3. CrossOver Runtime (if installed)
        let crossOverWine = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64"
        let crossOverServer = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wineserver"
        if fileManager.fileExists(atPath: crossOverWine) {
            discovered.append(
                RuntimeItem(
                    id: "crossover_runtime",
                    name: "CrossOver Compatibility Runtime",
                    version: "24.x / 26.x",
                    runnerPath: crossOverWine,
                    serverPath: crossOverServer,
                    metalSupportLevel: "D3DMetal / DXVK",
                    isDefault: false,
                    isHealthy: true
                )
            )
        }

        // 4. System / Homebrew Wine Fallback
        let brewWine = "/opt/homebrew/bin/wine64"
        let brewServer = "/opt/homebrew/bin/wineserver"
        if fileManager.fileExists(atPath: brewWine) {
            discovered.append(
                RuntimeItem(
                    id: "homebrew_wine",
                    name: "Homebrew Wine (Staging)",
                    version: "System",
                    runnerPath: brewWine,
                    serverPath: brewServer,
                    metalSupportLevel: "WineD3D / OpenGL",
                    isDefault: discovered.isEmpty,
                    isHealthy: true
                )
            )
        }

        self.runtimes = discovered
    }

    public func getRuntime(by id: String) -> RuntimeItem {
        return runtimes.first(where: { $0.id == id }) ?? runtimes.first ?? RuntimeItem(
            id: "fallback",
            name: "Fallback Runtime",
            version: "1.0",
            runnerPath: "/usr/local/bin/wine",
            serverPath: "/usr/local/bin/wineserver"
        )
    }

    public func locateBestWineRunner() -> String? {
        if let primary = runtimes.first(where: { $0.isDefault }) {
            return primary.runnerPath
        }
        return runtimes.first?.runnerPath
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

        let token = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled, .latencyCritical],
            reason: "Forge Windows Software Runtime - \(gameId)"
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
