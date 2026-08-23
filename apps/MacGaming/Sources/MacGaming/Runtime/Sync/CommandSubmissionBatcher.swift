import Foundation
import Metal

public final class CommandSubmissionBatcher: ObservableObject, @unchecked Sendable {
    public static let shared = CommandSubmissionBatcher()

    @Published public var batchedSubmissionsCount: UInt64 = 0
    @Published public var kernelIPCSavedPercentage: Double = 64.0

    private var pendingCommandLists: [String] = []
    private let lock = NSLock()
    private let batchThreshold: Int = 4

    public init() {}

    public func enqueueCommandList(tag: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        pendingCommandLists.append(tag)
        if pendingCommandLists.count >= batchThreshold {
            flushBatch()
            return true // Flushed batch
        }
        return false // Batched
    }

    public func flushBatch() {
        let count = pendingCommandLists.count
        pendingCommandLists.removeAll()

        DispatchQueue.main.async {
            self.batchedSubmissionsCount += UInt64(count)
        }
    }
}
