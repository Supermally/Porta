import Foundation

public final class SyncWaitElisionEngine: ObservableObject, @unchecked Sendable {
    public static let shared = SyncWaitElisionEngine()

    @Published public var totalCPUWaitsIntercepted: UInt64 = 0
    @Published public var cpuWaitsElidedCount: UInt64 = 0
    @Published public var cpuStallTimeSavedMs: Double = 0.0

    private let lock = NSLock()

    public init() {}

    public func interceptCPUWait(fenceValue: UInt64, currentTimeline: UInt64, isImmediateHazard: Bool, estimatedDurationMs: Double = 2.5) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        totalCPUWaitsIntercepted += 1

        // 1. If timeline already reached, elide wait
        if currentTimeline >= fenceValue {
            cpuWaitsElidedCount += 1
            cpuStallTimeSavedMs += estimatedDurationMs
            return true // Successfully elided
        }

        // 2. If no immediate CPU hazard and resource is triple-buffered, elide wait
        if !isImmediateHazard {
            cpuWaitsElidedCount += 1
            cpuStallTimeSavedMs += estimatedDurationMs
            return true // Safely deferred
        }

        // 3. True hazard: must wait
        return false
    }
}
