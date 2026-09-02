import Foundation

public final class ProcessHandleSyncCoordinator: ObservableObject, @unchecked Sendable {
    public static let shared = ProcessHandleSyncCoordinator()

    @Published public var activeSynchronizedHandlesCount: Int = 0
    @Published public var totalSignaledEvents: UInt64 = 0

    private var handleRegistry: [Int32: pid_t] = [:]
    private let lock = NSLock()

    public init() {}

    public func duplicateHandle(sourceHandle: Int32, targetPid: pid_t) -> Int32 {
        lock.lock()
        defer { lock.unlock() }

        let newHandle = sourceHandle + 1000
        handleRegistry[newHandle] = targetPid

        DispatchQueue.main.async {
            self.activeSynchronizedHandlesCount = self.handleRegistry.count
        }
        return newHandle
    }

    public func signalEvent(handle: Int32) {
        lock.lock()
        defer { lock.unlock() }

        DispatchQueue.main.async {
            self.totalSignaledEvents += 1
        }
    }
}
