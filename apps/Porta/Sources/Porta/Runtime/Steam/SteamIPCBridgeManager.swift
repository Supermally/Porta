import Foundation

public final class SteamIPCBridgeManager: ObservableObject, @unchecked Sendable {
    public static let shared = SteamIPCBridgeManager()

    @Published public var isIPCBridgeActive: Bool = false
    @Published public var activePipeConnectionsCount: Int = 0
    @Published public var routedMessagesCount: UInt64 = 0

    public init() {}

    public func verifySteamPipes(prefixURL: URL) -> Bool {
        let driveC = prefixURL.appendingPathComponent("drive_c", isDirectory: true)
        let steamDir = driveC.appendingPathComponent("Program Files (x86)/Steam", isDirectory: true)
        try? FileManager.default.createDirectory(at: steamDir, withIntermediateDirectories: true)
        return FileManager.default.fileExists(atPath: steamDir.path)
    }
}
