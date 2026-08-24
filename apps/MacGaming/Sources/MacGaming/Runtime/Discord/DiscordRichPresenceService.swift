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
    @Published public var activeGitCommit: String = "7c02a42"

    private init() {
        fetchGitState()
    }

    public func fetchGitState() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        if let _ = try? task.run() {
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let branch = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !branch.isEmpty {
                self.activeGitBranch = branch
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
            if let commit = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !commit.isEmpty {
                self.activeGitCommit = commit
            }
        }
    }

    public func updatePresence(for app: AppItem, mode: PresenceMode = .runningSoftware) {
        guard isEnabled else { return }
        
        self.currentMode = app.category == .games ? .runningGame : .runningSoftware
        if hideApplicationNames {
            self.statusDetail = "Running Windows Software"
        } else {
            self.statusDetail = app.name
        }
        self.stateMessage = "Through Forge • \(app.graphicsApi)"
    }

    public func setDeveloping(subsystem: String) {
        self.currentMode = .developing
        self.statusDetail = subsystem
        if showGitDetails {
            self.stateMessage = "\(activeGitBranch) • \(activeGitCommit)"
        } else {
            self.stateMessage = "Apple Silicon • ARM64"
        }
    }

    public func setTesting(feature: String, runtimeVersion: String = "1.0") {
        self.currentMode = .testing
        self.statusDetail = feature
        self.stateMessage = "Forge Runtime \(runtimeVersion)"
    }

    public func setInstalling(appName: String) {
        self.currentMode = .installing
        self.statusDetail = hideApplicationNames ? "Windows Software" : appName
        self.stateMessage = "Preparing Windows Environment"
    }

    public var formattedPreview: String {
        guard isEnabled else { return "Discord Rich Presence: Disabled" }
        return "\(currentMode.rawValue): \(statusDetail) (\(stateMessage))"
    }
}
