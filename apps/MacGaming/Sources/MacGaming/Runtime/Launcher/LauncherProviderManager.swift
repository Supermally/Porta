import Foundation
import SwiftUI
import AppKit

public final class LauncherProviderManager: ObservableObject, @unchecked Sendable {
    public static let shared = LauncherProviderManager()

    public init() {}

    public func launchApplication(
        _ app: AppItem,
        environment: EnvironmentItem,
        runtime: RuntimeItem,
        completion: @escaping (Result<Process?, Error>) -> Void
    ) {
        switch app.launcherProvider {
        case .steam(let appId):
            launchViaSteam(appId: appId, app: app, environment: environment, runtime: runtime, completion: completion)
        case .standalone:
            launchStandalone(app: app, environment: environment, runtime: runtime, completion: completion)
        case .epic(let appName):
            launchViaEpic(appName: appName, app: app, environment: environment, runtime: runtime, completion: completion)
        case .gog(let gameId):
            launchViaGOG(gameId: gameId, app: app, environment: environment, runtime: runtime, completion: completion)
        case .ubisoft, .ea, .custom:
            launchStandalone(app: app, environment: environment, runtime: runtime, completion: completion)
        }
    }

    // MARK: - Steam Launcher Provider

    private func launchViaSteam(
        appId: String,
        app: AppItem,
        environment: EnvironmentItem,
        runtime: RuntimeItem,
        completion: @escaping (Result<Process?, Error>) -> Void
    ) {
        let fileManager = FileManager.default
        let sikarugirSteam = fileManager.homeDirectoryForCurrentUser.path + "/Applications/Sikarugir/Steam.app"

        if fileManager.fileExists(atPath: sikarugirSteam) {
            // First check if Steam wrapper is already running
            let targetURL = URL(fileURLWithPath: sikarugirSteam)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            
            // Pass steam://rungameid/<appId> argument to Steam.app wrapper
            config.arguments = ["steam://rungameid/\(appId)"]

            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { runningApp, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(nil))
                }
            }
            return
        }

        // Fallback: Launch standalone executable directly inside prefix
        launchStandalone(app: app, environment: environment, runtime: runtime, completion: completion)
    }

    // MARK: - Standalone Application Launch

    private func launchStandalone(
        app: AppItem,
        environment: EnvironmentItem,
        runtime: RuntimeItem,
        completion: @escaping (Result<Process?, Error>) -> Void
    ) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: app.executablePath) else {
            let err = NSError(domain: "Forge.Launcher", code: 404, userInfo: [NSLocalizedDescriptionKey: "Executable not found at \(app.executablePath)"])
            completion(.failure(err))
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
        
        var runArgs = ["-x86_64", runtime.runnerPath, app.executablePath]
        if !app.arguments.isEmpty {
            let extra = app.arguments.components(separatedBy: " ").filter { !$0.isEmpty }
            runArgs.append(contentsOf: extra)
        }

        proc.arguments = runArgs

        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = environment.prefixPath
        env["WINEARCH"] = environment.architecture
        env["WINE_D3D_METAL"] = app.useD3DMetal ? "1" : "0"
        env["D3DMETAL"] = app.useD3DMetal ? "1" : "0"
        env["WINE_RETINA"] = "1"
        env["WINE_ENABLE_HIDPI"] = "1"
        env["WINEESYNC"] = app.enableEsync ? "1" : "0"
        env["WINEMSYNC"] = app.enableFsync ? "1" : "0"

        for (k, v) in environment.registryOverrides {
            env[k] = v
        }

        proc.environment = env

        do {
            try proc.run()
            completion(.success(proc))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Epic & GOG Providers

    private func launchViaEpic(
        appName: String,
        app: AppItem,
        environment: EnvironmentItem,
        runtime: RuntimeItem,
        completion: @escaping (Result<Process?, Error>) -> Void
    ) {
        if let url = URL(string: "com.epicgames.launcher://apps/\(appName)?action=launch&silent=true"),
           NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
            completion(.success(nil))
            return
        }
        launchStandalone(app: app, environment: environment, runtime: runtime, completion: completion)
    }

    private func launchViaGOG(
        gameId: String,
        app: AppItem,
        environment: EnvironmentItem,
        runtime: RuntimeItem,
        completion: @escaping (Result<Process?, Error>) -> Void
    ) {
        if let url = URL(string: "goggalaxy://openGameView/\(gameId)"),
           NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
            completion(.success(nil))
            return
        }
        launchStandalone(app: app, environment: environment, runtime: runtime, completion: completion)
    }
}
