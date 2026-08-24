import Foundation
import SwiftUI
import Combine

public enum PresenceMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case idle = "Idle"
    case developing = "Developing Forge"
    case testing = "Testing Compatibility"
    case debugging = "Debugging Subsystem"
    case installing = "Installing Software"
    case runningSoftware = "Running Windows Software"
    case runningGame = "Running Game"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .idle: return "moon.fill"
        case .developing: return "hammer.fill"
        case .testing: return "testtube.2"
        case .debugging: return "ant.fill"
        case .installing: return "shippingbox.fill"
        case .runningSoftware: return "macwindow"
        case .runningGame: return "gamecontroller.fill"
        }
    }
}

public final class DiscordRichPresenceService: ObservableObject, @unchecked Sendable {
    public static let shared = DiscordRichPresenceService()

    @Published public var isEnabled: Bool = true
    @Published public var hideApplicationNames: Bool = false
    @Published public var showGitDetails: Bool = true
    @Published public var currentMode: PresenceMode = .developing
    @Published public var statusDetail: String = "Application Discovery & Runtime"
    @Published public var stateMessage: String = "Apple Silicon • Metal 3"
    @Published public var activeGitBranch: String = "main"
    @Published public var activeGitCommit: String = "1eabcb5"
    @Published public var isConnectedToDiscord: Bool = false

    private var socketFD: Int32 = -1
    private var sessionStartTime: Int = Int(Date().timeIntervalSince1970)
    private let clientId = "1342621008064479303" // Default Discord Client ID for Mac Forge Platform
    private let ipcQueue = DispatchQueue(label: "org.forge.discord.ipc", qos: .background)

    private init() {
        fetchGitState()
        connectToDiscordIPC()
    }

    deinit {
        disconnectSocket()
    }

    // MARK: - Git State Inspection

    public func fetchGitState() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var branch = "main"
            var commit = "27d1560"

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            task.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
            let pipe = Pipe()
            task.standardOutput = pipe
            if let _ = try? task.run() {
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                    branch = str
                }
            }

            let commitTask = Process()
            commitTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            commitTask.arguments = ["rev-parse", "--short", "HEAD"]
            let commitPipe = Pipe()
            commitTask.standardOutput = commitPipe
            if let _ = try? commitTask.run() {
                commitTask.waitUntilExit()
                let data = commitPipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                    commit = str
                }
            }

            DispatchQueue.main.async {
                self.activeGitBranch = branch
                self.activeGitCommit = commit
            }
        }
    }

    // MARK: - State Updaters

    public func updatePresence(for app: AppItem, mode: PresenceMode = .runningSoftware) {
        guard isEnabled else { return }
        
        self.currentMode = app.category == .games ? .runningGame : .runningSoftware
        if hideApplicationNames {
            self.statusDetail = "Running Windows Software"
        } else {
            self.statusDetail = app.name
        }
        self.stateMessage = "Through Forge • \(app.graphicsApi)"
        self.sessionStartTime = Int(Date().timeIntervalSince1970)
        sendActivityUpdate()
    }

    public func setDeveloping(subsystem: String) {
        self.currentMode = .developing
        self.statusDetail = subsystem
        if showGitDetails {
            self.stateMessage = "\(activeGitBranch) • \(activeGitCommit)"
        } else {
            self.stateMessage = "Apple Silicon • ARM64"
        }
        sendActivityUpdate()
    }

    public func setTesting(feature: String, runtimeVersion: String = "1.0") {
        self.currentMode = .testing
        self.statusDetail = feature
        self.stateMessage = "Forge Runtime \(runtimeVersion)"
        sendActivityUpdate()
    }

    public func setInstalling(appName: String) {
        self.currentMode = .installing
        self.statusDetail = hideApplicationNames ? "Windows Software" : appName
        self.stateMessage = "Preparing Windows Environment"
        sendActivityUpdate()
    }

    public var formattedPreview: String {
        guard isEnabled else { return "Discord Rich Presence: Disabled" }
        return "\(currentMode.rawValue): \(statusDetail) (\(stateMessage))"
    }

    // MARK: - Discord Native UNIX Domain Socket IPC Client

    public func connectToDiscordIPC() {
        ipcQueue.async { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.disconnectSocket()

            let candidatePaths = (0...9).flatMap { i -> [String] in
                var paths: [String] = []
                paths.append("/tmp/discord-ipc-\(i)")
                if let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"] {
                    let cleaned = tmpDir.hasSuffix("/") ? String(tmpDir.dropLast()) : tmpDir
                    paths.append("\(cleaned)/discord-ipc-\(i)")
                }
                return paths
            }

            for socketPath in candidatePaths {
                if FileManager.default.fileExists(atPath: socketPath) {
                    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
                    guard fd >= 0 else { continue }

                    var addr = sockaddr_un()
                    addr.sun_family = sa_family_t(AF_UNIX)
                    let maxPathLen = MemoryLayout.size(ofValue: addr.sun_path)
                    withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                        socketPath.withCString { cStr in
                            _ = strncpy(UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self), cStr, maxPathLen)
                        }
                    }

                    let connectRes = withUnsafePointer(to: &addr) { ptr in
                        ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                            connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
                        }
                    }

                    if connectRes == 0 {
                        self.socketFD = fd
                        DispatchQueue.main.async {
                            self.isConnectedToDiscord = true
                        }
                        self.sendHandshake()
                        self.sendActivityUpdate()
                        return
                    } else {
                        close(fd)
                    }
                }
            }

            DispatchQueue.main.async {
                self.isConnectedToDiscord = false
            }
        }
    }

    private func sendHandshake() {
        let handshakeJSON = "{\"v\": 1, \"client_id\": \"\(clientId)\"}"
        sendPacket(opcode: 0, payloadJSON: handshakeJSON)
    }

    public func sendActivityUpdate() {
        ipcQueue.async { [weak self] in
            guard let self = self, self.isEnabled else { return }

            if self.socketFD < 0 {
                self.connectToDiscordIPC()
                return
            }

            let pid = ProcessInfo.processInfo.processIdentifier
            let start = self.sessionStartTime

            let activityJSON: [String: Any] = [
                "cmd": "SET_ACTIVITY",
                "args": [
                    "pid": pid,
                    "activity": [
                        "details": self.statusDetail,
                        "state": self.stateMessage,
                        "assets": [
                            "large_image": "forge_logo",
                            "large_text": "Forge Platform",
                            "small_image": "apple_silicon",
                            "small_text": "Apple Silicon • Metal 3"
                        ],
                        "timestamps": [
                            "start": start
                        ]
                    ]
                ],
                "nonce": UUID().uuidString
            ]

            if let data = try? JSONSerialization.data(withJSONObject: activityJSON, options: []),
               let jsonString = String(data: data, encoding: .utf8) {
                self.sendPacket(opcode: 1, payloadJSON: jsonString)
            }
        }
    }

    private func sendPacket(opcode: UInt32, payloadJSON: String) {
        guard socketFD >= 0, let payloadData = payloadJSON.data(using: .utf8) else { return }

        var header = Data()
        var op = opcode.littleEndian
        var len = UInt32(payloadData.count).littleEndian

        header.append(Data(bytes: &op, count: MemoryLayout<UInt32>.size))
        header.append(Data(bytes: &len, count: MemoryLayout<UInt32>.size))

        let fullPacket = header + payloadData
        _ = fullPacket.withUnsafeBytes { ptr in
            write(self.socketFD, ptr.baseAddress, fullPacket.count)
        }
    }

    private func disconnectSocket() {
        if socketFD >= 0 {
            close(socketFD)
            socketFD = -1
        }
        DispatchQueue.main.async {
            self.isConnectedToDiscord = false
        }
    }
}
