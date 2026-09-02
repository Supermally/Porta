import Foundation
import Metal

public final class MemoryPressureGovernor: ObservableObject, @unchecked Sendable {
    public static let shared = MemoryPressureGovernor()

    @Published public var totalEvictionsCount: Int = 0
    @Published public var totalBytesFreed: UInt64 = 0

    private var trackedPurgeableResources: [WeakResource] = []
    private let lock = NSLock()

    private final class WeakResource {
        weak var value: MTLResource?
        let estimatedBytes: UInt64
        init(value: MTLResource, estimatedBytes: UInt64) {
            self.value = value
            self.estimatedBytes = estimatedBytes
        }
    }

    public init() {}

    public func registerPurgeableResource(_ resource: MTLResource, estimatedBytes: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        trackedPurgeableResources.append(WeakResource(value: resource, estimatedBytes: estimatedBytes))
    }

    public func executeEmergencyMemoryTrim() {
        lock.lock()
        defer { lock.unlock() }

        var freed: UInt64 = 0
        var evictions: Int = 0

        for weakRes in trackedPurgeableResources {
            if let res = weakRes.value {
                let _ = res.setPurgeableState(.empty)
                freed += weakRes.estimatedBytes
                evictions += 1
            }
        }
        trackedPurgeableResources.removeAll()

        DispatchQueue.main.async {
            self.totalBytesFreed += freed
            self.totalEvictionsCount += evictions
        }
    }
}
