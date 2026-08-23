import Foundation

public final class ShaderPipelineService: ObservableObject, @unchecked Sendable {
    public static let shared = ShaderPipelineService()

    public let analyzer = ShaderAnalyzer.shared
    public let converter = MetalShaderConverter.shared
    public let diskCache = ShaderDiskCacheEngine.shared
    public let preWarmQueue = ShaderPreWarmQueue.shared

    public init() {}
}
