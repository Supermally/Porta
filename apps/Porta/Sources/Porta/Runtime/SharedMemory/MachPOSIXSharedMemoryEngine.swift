import Foundation
import Darwin

public final class MachPOSIXSharedMemoryEngine: ObservableObject, @unchecked Sendable {
    public static let shared = MachPOSIXSharedMemoryEngine()

    @Published public var totalActiveMappingsCount: Int = 0
    @Published public var totalAllocatedSharedBytes: UInt64 = 0
    @Published public var hardwarePageSizeKB: Int = 16

    private let appleSiliconPageSize: Int = 16384 // 16KB
    private let windowsGranularity: Int = 65536    // 64KB
    private let lock = NSLock()

    public init() {}

    public func alignSizeToHardwarePages(size: Int) -> Int {
        let remainder = size % appleSiliconPageSize
        if remainder == 0 { return max(size, appleSiliconPageSize) }
        return size + (appleSiliconPageSize - remainder)
    }

    public func alignSizeToWindowsGranularity(size: Int) -> Int {
        let remainder = size % windowsGranularity
        if remainder == 0 { return max(size, windowsGranularity) }
        return size + (windowsGranularity - remainder)
    }

    public func createSharedMemoryRegion(name: String, sizeBytes: Int) -> (name: String, alignedSize: Int) {
        lock.lock()
        defer { lock.unlock() }

        let aligned = alignSizeToHardwarePages(size: sizeBytes)
        DispatchQueue.main.async {
            self.totalActiveMappingsCount += 1
            self.totalAllocatedSharedBytes += UInt64(aligned)
        }
        return (name, aligned)
    }

    public func releaseSharedMemoryRegion(alignedSize: Int) {
        lock.lock()
        defer { lock.unlock() }

        DispatchQueue.main.async {
            if self.totalActiveMappingsCount > 0 {
                self.totalActiveMappingsCount -= 1
            }
            if self.totalAllocatedSharedBytes >= UInt64(alignedSize) {
                self.totalAllocatedSharedBytes -= UInt64(alignedSize)
            }
        }
    }
}
