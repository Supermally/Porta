import Foundation

public struct SharedMemoryRegionDescriptor: Sendable {
    public let regionId: String
    public let sizeBytes: Int
    public let creatorPid: pid_t
    public let isZeroCopyActive: Bool
}

public final class CrossProcessSharedMemoryEngine: ObservableObject, @unchecked Sendable {
    public static let shared = CrossProcessSharedMemoryEngine()

    @Published public var activeRegionsCount: Int = 0
    @Published public var totalAllocatedSharedBytes: UInt64 = 0
    @Published public var isZeroCopyTransferEngaged: Bool = true

    private var regions: [String: SharedMemoryRegionDescriptor] = [:]
    private let lock = NSLock()

    public init() {}

    public func allocateSharedRegion(regionId: String, sizeBytes: Int, pid: pid_t) -> SharedMemoryRegionDescriptor {
        lock.lock()
        defer { lock.unlock() }

        let desc = SharedMemoryRegionDescriptor(
            regionId: regionId,
            sizeBytes: sizeBytes,
            creatorPid: pid,
            isZeroCopyActive: true
        )
        regions[regionId] = desc

        DispatchQueue.main.async {
            self.activeRegionsCount = self.regions.count
            self.totalAllocatedSharedBytes += UInt64(sizeBytes)
        }
        return desc
    }

    public func releaseSharedRegion(regionId: String) {
        lock.lock()
        defer { lock.unlock() }

        if let desc = regions.removeValue(forKey: regionId) {
            DispatchQueue.main.async {
                self.activeRegionsCount = self.regions.count
                if self.totalAllocatedSharedBytes >= UInt64(desc.sizeBytes) {
                    self.totalAllocatedSharedBytes -= UInt64(desc.sizeBytes)
                }
            }
        }
    }
}
