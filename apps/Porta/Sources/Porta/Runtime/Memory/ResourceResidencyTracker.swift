import Foundation
import Metal

public final class ResourceResidencyTracker: ObservableObject, @unchecked Sendable {
    public static let shared = ResourceResidencyTracker()

    @Published public var currentFrameIndex: UInt64 = 0
    @Published public var activeResidentResourcesCount: Int = 0
    @Published public var recycledResourcesCount: Int = 0

    private var pendingReclamations: [UInt64: [MTLResource]] = [:]
    private let lock = NSLock()

    public init() {}

    public func trackResourceUsage(_ resource: MTLResource, frameIndex: UInt64) {
        lock.lock()
        defer { lock.unlock() }

        var list = pendingReclamations[frameIndex] ?? []
        list.append(resource)
        pendingReclamations[frameIndex] = list

        DispatchQueue.main.async {
            self.activeResidentResourcesCount += 1
        }
    }

    public func onFrameCompleted(frameIndex: UInt64) {
        lock.lock()
        defer { lock.unlock() }

        if let resources = pendingReclamations.removeValue(forKey: frameIndex) {
            let count = resources.count
            DispatchQueue.main.async {
                self.recycledResourcesCount += count
                self.activeResidentResourcesCount = max(0, self.activeResidentResourcesCount - count)
                self.currentFrameIndex = frameIndex
            }
        }
    }
}
