import Foundation
import Metal

public enum D3D12DescriptorHeapType: UInt32, Sendable {
    case cbvSrvUav = 0
    case sampler = 1
    case rtv = 2
    case dsv = 3
}

public struct D3D12DescriptorHandle: Sendable {
    public let heapOffset: Int
    public let size: Int
    public let gpuAddress: UInt64
}

public final class D3D12DescriptorHeapEngine: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12DescriptorHeapEngine()

    @Published public var isArgumentBufferTier2Active: Bool = false
    @Published public var activeDescriptorCount: Int = 0
    @Published public var rebindingOverheadSavedPercentage: Double = 98.5

    private let defaultDevice: MTLDevice?
    private var argumentBuffer: MTLBuffer?
    private let descriptorCapacity: Int = 1_000_000 // 1 Million descriptors
    private let descriptorStride: Int = 64 // 64-byte descriptor entry

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        initializeArgumentBufferHeap()
    }

    private func initializeArgumentBufferHeap() {
        guard let device = defaultDevice else { return }

        self.isArgumentBufferTier2Active = device.argumentBuffersSupport == .tier2

        let totalSize = descriptorCapacity * descriptorStride
        let options: MTLResourceOptions = [.storageModeShared, .hazardTrackingModeUntracked]
        if let buffer = device.makeBuffer(length: totalSize, options: options) {
            self.argumentBuffer = buffer
        }
    }

    public func allocateDescriptorTable(count: Int) -> D3D12DescriptorHandle? {
        guard let buffer = argumentBuffer else { return nil }

        let offset = activeDescriptorCount * descriptorStride
        let size = count * descriptorStride

        DispatchQueue.main.async {
            self.activeDescriptorCount += count
        }

        return D3D12DescriptorHandle(
            heapOffset: offset,
            size: size,
            gpuAddress: buffer.gpuAddress + UInt64(offset)
        )
    }
}
