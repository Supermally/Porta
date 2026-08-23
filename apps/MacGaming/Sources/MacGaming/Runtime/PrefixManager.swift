import Foundation

public final class PrefixManager: Sendable {
    public static let shared = PrefixManager()

    public var basePrefixDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MacGaming/Prefixes", isDirectory: true)
    }

    public var defaultPrefixURL: URL {
        basePrefixDirectory.appendingPathComponent("default", isDirectory: true)
    }

    public init() {
        ensureBaseDirectoriesExist()
    }

    public func ensureBaseDirectoriesExist() {
        try? FileManager.default.createDirectory(at: basePrefixDirectory, withIntermediateDirectories: true)
    }

    public func prefixURL(for gameId: String, isolated: Bool = false) -> URL {
        if isolated {
            let sanitized = gameId.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
            let url = basePrefixDirectory.appendingPathComponent(sanitized, isDirectory: true)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        return defaultPrefixURL
    }

    public func shaderDiskCacheURL(for gameId: String) -> URL {
        let prefix = prefixURL(for: gameId, isolated: false)
        let cacheDir = prefix.appendingPathComponent("metal_pso_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }

    public func preparePrefix(for gameId: String, config: RuntimeEnvironmentConfig) -> URL {
        let prefix = prefixURL(for: gameId, isolated: false)
        let driveC = prefix.appendingPathComponent("drive_c", isDirectory: true)
        let system32 = driveC.appendingPathComponent("windows/system32", isDirectory: true)
        let syswow64 = driveC.appendingPathComponent("windows/syswow64", isDirectory: true)

        try? FileManager.default.createDirectory(at: system32, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: syswow64, withIntermediateDirectories: true)

        return prefix
    }
}
