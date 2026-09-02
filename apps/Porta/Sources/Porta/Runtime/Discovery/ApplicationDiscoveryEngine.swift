import Foundation
import SwiftUI
import Combine

public final class ApplicationDiscoveryEngine: ObservableObject, @unchecked Sendable {
    public static let shared = ApplicationDiscoveryEngine()

    @Published public var discoveredApplications: [AppItem] = []
    @Published public var isScanning: Bool = false
    @Published public var lastScanTimestamp: Date? = nil

    private var cancellables = Set<AnyCancellable>()
    private var directoryWatchSources: [DispatchSourceFileSystemObject] = []

    public init() {}

    deinit {
        stopAllWatchers()
    }

    // MARK: - Core Discovery Scanner

    public func scanAllManagedEnvironments(environments: [EnvironmentItem]) -> [AppItem] {
        var results: [AppItem] = []
        let fileManager = FileManager.default

        // 1. Scan Steam Application and Managed Prefix
        let sikarugirSteam = fileManager.homeDirectoryForCurrentUser.path + "/Applications/Sikarugir/Steam.app"
        if fileManager.fileExists(atPath: sikarugirSteam) {
            let steamItem = AppItem(
                id: "steam_launcher",
                name: "Steam",
                category: .launchers,
                publisher: "Valve Corporation",
                version: "1.0.0",
                architecture: "x86_64",
                iconUrl: "https://upload.wikimedia.org/wikipedia/commons/8/83/Steam_icon_logo.svg",
                headerImageUrl: "https://cdn.cloudflare.steamstatic.com/store/home/store_home_share.jpg",
                executablePath: sikarugirSteam + "/Contents/drive_c/Program Files (x86)/Steam/steam.exe",
                arguments: "-no-cef-sandbox -allosarches",
                workingDirectory: sikarugirSteam + "/Contents/drive_c/Program Files (x86)/Steam",
                environmentId: "steam_env",
                runtimeId: "forge_wine10",
                launcherProvider: .standalone,
                compatibilityTier: .native,
                graphicsApi: "Apple D3DMetal (Metal 3)",
                useD3DMetal: true,
                enableHud: false,
                isFavorite: true,
                tags: ["Storefront", "Launcher", "Valve"]
            )
            results.append(steamItem)

            // Discover games inside Steam prefix
            let steamPrefix = sikarugirSteam + "/Contents/SharedSupport/prefix"
            let steamGames = scanSteamApps(inPrefix: steamPrefix, environmentId: "steam_env")
            results.append(contentsOf: steamGames)
        }

        // 2. Scan Custom & Managed Environments
        for env in environments {
            let envApps = scanEnvironment(env)
            for app in envApps {
                if !results.contains(where: { $0.id == app.id }) {
                    results.append(app)
                }
            }
        }

        // 3. Scan Legacy / Porta isolated prefixes
        let legacyPrefixesDir = fileManager.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/prefixes"
        if let subdirs = try? fileManager.contentsOfDirectory(atPath: legacyPrefixesDir) {
            for sub in subdirs {
                let p = legacyPrefixesDir + "/" + sub
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: p, isDirectory: &isDir), isDir.boolValue {
                    let envItem = EnvironmentItem(
                        id: sub,
                        name: sub.capitalized,
                        description: "Isolated Environment",
                        prefixPath: p
                    )
                    let found = scanEnvironment(envItem)
                    for app in found where !results.contains(where: { $0.id == app.id }) {
                        results.append(app)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.discoveredApplications = results
            self.lastScanTimestamp = Date()
            self.isScanning = false
        }

        return results
    }

    // MARK: - Steam Apps Scanner (.acf parser)

    public func scanSteamApps(inPrefix prefixPath: String, environmentId: String) -> [AppItem] {
        var items: [AppItem] = []
        let fileManager = FileManager.default
        let steamAppsPath = prefixPath + "/drive_c/Program Files (x86)/Steam/steamapps"

        guard fileManager.fileExists(atPath: steamAppsPath),
              let files = try? fileManager.contentsOfDirectory(atPath: steamAppsPath) else {
            return []
        }

        for file in files where file.hasPrefix("appmanifest_") && file.hasSuffix(".acf") {
            let manifestPath = steamAppsPath + "/" + file
            if let content = try? String(contentsOfFile: manifestPath, encoding: .utf8) {
                if let appItem = parseSteamManifest(content: content, steamAppsPath: steamAppsPath, environmentId: environmentId) {
                    items.append(appItem)
                }
            }
        }

        return items
    }

    private func parseSteamManifest(content: String, steamAppsPath: String, environmentId: String) -> AppItem? {
        var dict: [String: String] = [:]
        content.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("\"") {
                let parts = trimmed.components(separatedBy: "\"")
                if parts.count >= 4 {
                    let key = parts[1].lowercased()
                    let val = parts[3]
                    dict[key] = val
                }
            }
        }

        guard let appId = dict["appid"],
              let name = dict["name"],
              let installDir = dict["installdir"] else {
            return nil
        }

        // Exclude common runtime dependencies from being listed as primary games
        if appId == "228980" || name.contains("Steamworks Common Redistributables") {
            return nil
        }

        let gameDir = steamAppsPath + "/common/" + installDir
        guard FileManager.default.fileExists(atPath: gameDir) else {
            return nil
        }
        let (execPath, architecture) = findPrimaryExecutable(in: gameDir)
        guard !execPath.isEmpty, FileManager.default.fileExists(atPath: execPath) else {
            return nil
        }

        let sizeBytes = Int64(dict["sizeondisk"] ?? "0") ?? 0

        return AppItem(
            id: "steam_game_\(appId)",
            name: name,
            category: .games,
            publisher: "Steam Title",
            version: "Steam Build",
            architecture: architecture,
            iconUrl: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/header.jpg",
            headerImageUrl: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/header.jpg",
            executablePath: execPath,
            arguments: "",
            workingDirectory: gameDir,
            environmentId: environmentId,
            runtimeId: "forge_wine10",
            launcherProvider: .steam(appId: appId),
            compatibilityTier: .compatible,
            graphicsApi: "Apple D3DMetal (DirectX 11/12)",
            useD3DMetal: true,
            enableHud: false,
            sizeOnDisk: sizeBytes,
            tags: ["Steam", "Game", installDir]
        )
    }

    // MARK: - Generic Environment Scanner (Start Menu, Program Files & Registry)

    public func scanEnvironment(_ environment: EnvironmentItem) -> [AppItem] {
        // Steam environment and Steam app directories are scanned exclusively by scanSteamApps to avoid exposing internal daemons
        if environment.id == "steam_env" || environment.prefixPath.contains("Steam.app") {
            return []
        }

        var items: [AppItem] = []
        let fileManager = FileManager.default
        let prefix = environment.prefixPath

        let searchDirs = [
            prefix + "/drive_c/Program Files",
            prefix + "/drive_c/Program Files (x86)",
            prefix + "/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs"
        ]

        let excludedSubstrings = [
            "unins", "uninst", "helper", "crash", "update", "steam.exe", "steamwebhelper",
            "steamservice", "steamerrorreporter", "winedevice", "wineserver", "explorer.exe",
            "iexplore", "internet explorer", "wine", "winebrowser", "winemine", "wordpad",
            "services.exe", "svchost", "winlogon", "msiexec", "dxdiag", "rundll32",
            "regedit", "reg.exe", "cmd.exe", "conhost", "taskkill", "tasklist",
            "winemenubuilder", "winhlp32", "wordpad", "write.exe", "control.exe",
            "hh.exe", "attrib", "cacls", "fc.exe", "find.exe", "findstr", "help.exe",
            "hostname", "ipconfig", "net.exe", "netstat", "ping.exe", "route.exe",
            "sc.exe", "shutdown", "sort.exe", "subst.exe", "systeminfo", "tracert",
            "xcopy", "cabarc", "expand.exe", "extrac32", "chkdsk", "diskmgmt",
            "dxsetup", "vcredist", "vc_redist", "dotnet", "directx", "redist",
            "gldriverquery", "vulkaninfo", "cef", "subprocess", "driver", "vulkan",
            "d3d11", "d3d12", "unitycrash", "install", "setup.exe", "autorun"
        ]

        for dir in searchDirs {
            let dirURL = URL(fileURLWithPath: dir)
            guard fileManager.fileExists(atPath: dir),
                  let enumerator = fileManager.enumerator(at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsPackageDescendants, .skipsHiddenFiles]) else { continue }

            for case let fileURL as URL in enumerator {
                let path = fileURL.path
                let lowerPath = path.lowercased()

                if (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    if lowerPath.contains("/windows") || lowerPath.contains("/system32") || lowerPath.contains("/syswow64") || lowerPath.contains("/steam") || lowerPath.contains("/temp") || lowerPath.contains("/node_modules") || lowerPath.contains("/cache") {
                        enumerator.skipDescendants()
                        continue
                    }
                }

                if fileURL.pathExtension.lowercased() == "exe" {
                    let fileName = fileURL.lastPathComponent
                    let lowerName = fileName.lowercased()

                    let shouldExclude = excludedSubstrings.contains { lowerName.contains($0) || lowerPath.contains($0) }
                    if shouldExclude {
                        continue
                    }

                    let cleanName = (fileName as NSString).deletingPathExtension
                    let category = inferCategory(for: cleanName, path: path)

                    let app = AppItem(
                        id: "env_\(environment.id)_\(cleanName.lowercased())",
                        name: cleanName.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ").capitalized,
                        category: category,
                        publisher: "Windows Software",
                        version: "1.0",
                        architecture: "x64",
                        headerImageUrl: nil,
                        executablePath: path,
                        workingDirectory: (path as NSString).deletingLastPathComponent,
                        environmentId: environment.id,
                        runtimeId: environment.defaultRuntimeId,
                        launcherProvider: .standalone,
                        compatibilityTier: .compatible,
                        graphicsApi: "DirectX 11 / Metal",
                        useD3DMetal: true,
                        tags: [category.rawValue, environment.name]
                    )

                    if !items.contains(where: { $0.executablePath == app.executablePath }) {
                        items.append(app)
                    }
                }
            }
        }

        return items
    }

    private func inferCategory(for name: String, path: String) -> ApplicationCategory {
        let lower = name.lowercased() + " " + path.lowercased()
        if lower.contains("photoshop") || lower.contains("blender") || lower.contains("gimp") || lower.contains("illustrator") || lower.contains("premiere") || lower.contains("paint") {
            return .creative
        } else if lower.contains("code") || lower.contains("studio") || lower.contains("git") || lower.contains("python") || lower.contains("terminal") || lower.contains("compiler") {
            return .development
        } else if lower.contains("7-zip") || lower.contains("7z") || lower.contains("winrar") || lower.contains("notepad") || lower.contains("tool") || lower.contains("explorer") || lower.contains("calc") {
            return .utilities
        } else if lower.contains("steam") || lower.contains("epic") || lower.contains("gog") || lower.contains("origin") || lower.contains("uplay") || lower.contains("battle") {
            return .launchers
        } else if lower.contains("game") || lower.contains("shipping") || lower.contains("unity") || lower.contains("unreal") || lower.contains("binaries") {
            return .games
        }
        return .other
    }

    private func findPrimaryExecutable(in directory: String) -> (String, String) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.subpathsOfDirectory(atPath: directory) else {
            return (directory, "x64")
        }

        var candidates: [String] = []
        for file in files where file.lowercased().hasSuffix(".exe") {
            let lower = file.lowercased()
            if !lower.contains("crash") && !lower.contains("unitycrash") && !lower.contains("unins") && !lower.contains("redist") {
                candidates.append(directory + "/" + file)
            }
        }

        // Prioritize Win64 Shipping binaries if Unreal
        if let shipping = candidates.first(where: { $0.lowercased().contains("win64-shipping") }) {
            return (shipping, "x64")
        }

        if let first = candidates.first {
            return (first, "x64")
        }

        return (directory, "x64")
    }

    // MARK: - Live Directory Watchers

    public func startWatchingEnvironment(prefixPath: String, onChange: @escaping () -> Void) {
        let steamApps = prefixPath + "/drive_c/Program Files (x86)/Steam/steamapps"
        let pathsToWatch = [steamApps, prefixPath + "/drive_c/Program Files"]

        for path in pathsToWatch {
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .extend, .attrib, .link],
                queue: DispatchQueue.global(qos: .background)
            )

            source.setEventHandler {
                DispatchQueue.main.async {
                    onChange()
                }
            }

            source.setCancelHandler {
                close(fd)
            }

            source.resume()
            directoryWatchSources.append(source)
        }
    }

    public func stopAllWatchers() {
        for source in directoryWatchSources {
            source.cancel()
        }
        directoryWatchSources.removeAll()
    }
}
