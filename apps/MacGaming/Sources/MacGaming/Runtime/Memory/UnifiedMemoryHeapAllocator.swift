import Foundation
import Metal

public struct UnifiedSubAllocation: @unchecked Sendable {
    public let offset: Int
    public let size: Int
    public let buffer: MTLBuffer
    public let rawPointer: UnsafeMutableRawPointer

    public init(offset: Int, size: Int, buffer: MTLBuffer) {
        self.offset = offset
        self.size = size
        self.buffer = buffer
        self.rawPointer = buffer.contents().advanced(by: offset)
    }
}

public final class UnifiedMemoryHeapAllocator: ObservableObject, @unchecked Sendable {
    public static let shared = UnifiedMemoryHeapAllocator()

    @Published public var totalAllocatedBytes: Int = 0
    @Published public var activeSubAllocationsCount: Int = 0
    @Published public var copiesEliminatedCount: Int = 0

    private let defaultDevice: MTLDevice?
    private var primaryHeap: MTLHeap?
    private var primaryBuffer: MTLBuffer?
    private var currentOffset: Int = 0
    private let heapSize: Int = 64 * 1024 * 1024 // 64 MB chunk
    private let alignment: Int = 256
    private let lock = NSLock()

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        allocatePrimaryHeap()
    }

    private func allocatePrimaryHeap() {
        guard let device = defaultDevice else { return }

        // Create large unified shared buffer directly on Apple Silicon UMA
        let bufferOptions: MTLResourceOptions = [.storageModeShared, .hazardTrackingModeUntracked]
        if let buffer = device.makeBuffer(length: heapSize, options: bufferOptions) {
            self.primaryBuffer = buffer
            self.totalAllocatedBytes = heapSize
        }
    }

    public func allocateSubBuffer(size: Int) -> UnifiedSubAllocation? {
        lock.lock()
        defer { lock.unlock() }

        guard let buffer = primaryBuffer else { return nil }

        let alignedSize = (size + alignment - 1) & ~(alignment - 1)
        if currentOffset + alignedSize > heapSize {
            // Ring buffer wrap-around for dynamic frame resources
            currentOffset = 0
        }

        let allocOffset = currentOffset
        currentOffset += alignedSize

        DispatchQueue.main.async {
            self.activeSubAllocationsCount += 1
            self.copiesEliminatedCount += 1 // Each direct allocation avoids 2 staging copies
        }

        return UnifiedSubAllocation(offset: allocOffset, size: size, buffer: buffer)
    }

    public func resetArena() {
        lock.lock()
        defer { lock.unlock() }
        currentOffset = 0
    }
}
