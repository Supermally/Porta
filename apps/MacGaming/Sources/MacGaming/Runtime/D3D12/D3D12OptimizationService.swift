import Foundation

public final class D3D12OptimizationService: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12OptimizationService()

    public let barriers = D3D12BarrierOptimizer.shared
    public let descriptors = D3D12DescriptorHeapEngine.shared
    public let indirect = D3D12IndirectCommandEngine.shared
    public let multiplexer = D3D12CommandMultiplexer.shared
    public let pipelineCache = D3D12PipelineCacheManager.shared

    public init() {}
}
