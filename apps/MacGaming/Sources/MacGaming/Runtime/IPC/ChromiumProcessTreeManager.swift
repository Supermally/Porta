import Foundation

public enum ChromiumProcessRole: String, CaseIterable, Codable, Identifiable, Sendable {
    case browser = "Browser (Master Coordinator)"
    case renderer = "Renderer (Web / Store UI)"
    case gpuProcess = "GPU Process (Metal Compositor)"
    case utility = "Utility / Network Worker"
    case crashHandler = "Crashpad Handler"

    public var id: String { rawValue }
}

public struct TrackedChromiumProcess: Identifiable, Sendable {
    public let id: pid_t
    public let role: ChromiumProcessRole
    public let parentPid: pid_t
    public let commandLine: String
    public let startTime: Date
}

public final class ChromiumProcessTreeManager: ObservableObject, @unchecked Sendable {
    public static let shared = ChromiumProcessTreeManager()

    @Published public var activeProcesses: [TrackedChromiumProcess] = []
    @Published public var activeProcessCount: Int = 0
    @Published public var isGpuProcessHealthy: Bool = true

    private let lock = NSLock()

    public init() {}

    public func registerProcess(pid: pid_t, role: ChromiumProcessRole, parentPid: pid_t, commandLine: String) {
        lock.lock()
        defer { lock.unlock() }

        let proc = TrackedChromiumProcess(
            id: pid,
            role: role,
            parentPid: parentPid,
            commandLine: commandLine,
            startTime: Date()
        )
        activeProcesses.append(proc)

        DispatchQueue.main.async {
            self.activeProcessCount = self.activeProcesses.count
            if role == .gpuProcess {
                self.isGpuProcessHealthy = true
            }
        }
    }

    public func unregisterProcess(pid: pid_t) {
        lock.lock()
        defer { lock.unlock() }

        activeProcesses.removeAll(where: { $0.id == pid })
        DispatchQueue.main.async {
            self.activeProcessCount = self.activeProcesses.count
        }
    }
}
