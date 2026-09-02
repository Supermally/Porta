import Foundation
import Metal

public final class D3D12CommandMultiplexer: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12CommandMultiplexer()

    @Published public var activeCommandQueuesCount: Int = 1
    @Published public var parallelEncodersDispatchedCount: UInt64 = 0
    @Published public var timelineFenceSyncCount: UInt64 = 0

    private let defaultDevice: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var fenceSharedEvent: MTLSharedEvent?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        if let device = defaultDevice {
            self.commandQueue = device.makeCommandQueue()
            self.fenceSharedEvent = device.makeSharedEvent()
        }
    }

    public func makeParallelRenderEncoder(passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) -> MTLParallelRenderCommandEncoder? {
        let encoder = commandBuffer.makeParallelRenderCommandEncoder(descriptor: passDescriptor)
        if encoder != nil {
            DispatchQueue.main.async {
                self.parallelEncodersDispatchedCount += 1
            }
        }
        return encoder
    }

    public func signalD3D12Fence(fenceValue: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = fenceSharedEvent else { return }
        commandBuffer.encodeSignalEvent(event, value: fenceValue)

        DispatchQueue.main.async {
            self.timelineFenceSyncCount += 1
        }
    }

    public func waitD3D12Fence(fenceValue: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = fenceSharedEvent else { return }
        commandBuffer.encodeWaitForEvent(event, value: fenceValue)
    }
}
