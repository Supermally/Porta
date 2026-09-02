import Foundation
import SwiftUI
import Combine

public final class EnvironmentManager: ObservableObject, @unchecked Sendable {
    public static let shared = EnvironmentManager()

    @Published public var environments: [EnvironmentItem] = []
    @Published public var selectedEnvironmentId: String = "default"

    private let storageKey = "Forge.Environments"

    public init() {
        loadEnvironments()
    }

    // MARK: - Persistence & Initial Setup

    public func loadEnvironments() {
        let fileManager = FileManager.default
        let appSupport = fileManager.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta"
        let defaultPrefix = appSupport + "/prefixes/default"
        let steamPrefix = fileManager.homeDirectoryForCurrentUser.path + "/Applications/Sikarugir/Steam.app/Contents/SharedSupport/prefix"

        try? fileManager.createDirectory(atPath: defaultPrefix, withIntermediateDirectories: true)

        var loaded: [EnvironmentItem] = []

        // Default Environment
        loaded.append(
            EnvironmentItem(
                id: "default",
                name: "Default Environment",
                description: "Standard Windows 64-bit environment with Apple D3DMetal & DirectX 11/12 support.",
                prefixPath: defaultPrefix,
                defaultRuntimeId: "forge_wine10",
                architecture: "win64",
                isIsolated: false
            )
        )

        // Steam Environment
        if fileManager.fileExists(atPath: steamPrefix) {
            loaded.append(
                EnvironmentItem(
                    id: "steam_env",
                    name: "Steam Environment",
                    description: "Isolated environment for Windows Steam client & Steam titles.",
                    prefixPath: steamPrefix,
                    defaultRuntimeId: "forge_wine10",
                    architecture: "win64",
                    isIsolated: true,
                    installedDependencies: ["Steam Client", "D3DMetal", "MoltenVK"]
                )
            )
        }

        // Custom environments from storage
        let customFile = appSupport + "/environments.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: customFile)),
           let customEnvs = try? JSONDecoder().decode([EnvironmentItem].self, from: data) {
            for env in customEnvs {
                if !loaded.contains(where: { $0.id == env.id }) {
                    loaded.append(env)
                }
            }
        }

        self.environments = loaded
    }

    public func saveEnvironments() {
        let appSupport = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta"
        let customFile = appSupport + "/environments.json"
        let customOnly = environments.filter { $0.id != "default" && $0.id != "steam_env" }
        if let data = try? JSONEncoder().encode(customOnly) {
            try? data.write(to: URL(fileURLWithPath: customFile))
        }
    }

    public func createEnvironment(name: String, description: String = "", isIsolated: Bool = true) -> EnvironmentItem {
        let id = "env_" + UUID().uuidString.prefix(8).lowercased()
        let prefixPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/prefixes/\(id)"
        try? FileManager.default.createDirectory(atPath: prefixPath, withIntermediateDirectories: true)

        let newEnv = EnvironmentItem(
            id: id,
            name: name,
            description: description,
            prefixPath: prefixPath,
            defaultRuntimeId: "forge_wine10",
            architecture: "win64",
            isIsolated: isIsolated
        )

        environments.append(newEnv)
        saveEnvironments()
        return newEnv
    }

    public func getEnvironment(by id: String) -> EnvironmentItem {
        return environments.first(where: { $0.id == id }) ?? environments.first ?? EnvironmentItem(
            id: "default",
            name: "Default",
            prefixPath: FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/prefixes/default"
        )
    }
}
