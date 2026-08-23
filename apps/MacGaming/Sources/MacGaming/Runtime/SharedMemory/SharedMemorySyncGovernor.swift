import Foundation
import Darwin

public final class SharedMemorySyncGovernor: ObservableObject, @unchecked Sendable {
    public static let shared = SharedMemorySyncGovernor()

    @Published public var syncOperationsCount: UInt64 = 0
    @Published public var averageSyncLatencyMicros: Double = 0.12

    private let lock = NSLock()

    public init() {}

    public func executeMemoryBarrier() {
        // Full hardware memory barrier
        OSMemoryBarrier()

        lock.lock()
        defer { lock.unlock() }

        DispatchQueue.main.async {
            self.syncOperationsCount += 1
        }
    }

    public func synchronizeMappedRegion(address: UnsafeMutableRawPointer?, size: Int) -> Bool {
        guard let addr = address, size > 0 else {
            executeMemoryBarrier()
            return true
        }

        let result = msync(addr, size, MS_ASYNC | MS_INVALIDATE)
        executeMemoryBarrier()
        return result == 0
    }
}
