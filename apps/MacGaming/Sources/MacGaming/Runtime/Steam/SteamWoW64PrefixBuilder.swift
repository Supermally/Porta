import Foundation

public final class SteamWoW64PrefixBuilder: Sendable {
    public static let shared = SteamWoW64PrefixBuilder()

    public init() {}

    public func provisionUnifiedSteamPrefix(at prefixURL: URL) -> Bool {
        let driveC = prefixURL.appendingPathComponent("drive_c", isDirectory: true)
        let system32 = driveC.appendingPathComponent("windows/system32", isDirectory: true)
        let syswow64 = driveC.appendingPathComponent("windows/syswow64", isDirectory: true)
        let steamX86 = driveC.appendingPathComponent("Program Files (x86)/Steam", isDirectory: true)
        let steamApps = steamX86.appendingPathComponent("steamapps/common", isDirectory: true)

        let dirs = [system32, syswow64, steamX86, steamApps]
        for dir in dirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return true
    }
}
