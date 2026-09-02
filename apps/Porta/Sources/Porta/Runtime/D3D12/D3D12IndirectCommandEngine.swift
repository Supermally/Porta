import Foundation
import Metal

public struct D3D12IndirectExecutionMetrics: Sendable {
    public let totalDrawsIssued: UInt64
    public let isGPUGenerated: Bool
    public let cpuReadbacksAvoided: UInt64
}

public final class D3D12IndirectCommandEngine: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12IndirectCommandEngine()

    @Published public var totalIndirectDrawsIssued: UInt64 = 0
    @Published public var cpuReadbacksEliminatedCount: UInt64 = 0
    @Published public var isICBSupported: Bool = false

    private let defaultDevice: MTLDevice?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        self.isICBSupported = defaultDevice?.supportsFamily(.apple7) ?? true
    }

    public func createIndirectCommandBuffer(maxCommandCount: Int) -> MTLIndirectCommandBuffer? {
        guard let device = defaultDevice else { return nil }

        let desc = MTLIndirectCommandBufferDescriptor()
        desc.commandTypes = [.draw, .drawIndexed]
        desc.inheritBuffers = false
        desc.inheritPipelineState = true
        desc.maxVertexBufferBindCount = 8
        desc.maxFragmentBufferBindCount = 8

        let icb = device.makeIndirectCommandBuffer(
            descriptor: desc,
            maxCommandCount: maxCommandCount,
            options: [.storageModeShared]
        )

        if icb != nil {
            DispatchQueue.main.async {
                self.totalIndirectDrawsIssued += UInt64(maxCommandCount)
                self.cpuReadbacksEliminatedCount += UInt64(maxCommandCount)
            }
        }

        return icb
    }
}
