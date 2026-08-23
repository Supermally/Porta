import Foundation

public final class GraphicsArchitectureService: ObservableObject, @unchecked Sendable {
    public static let shared = GraphicsArchitectureService()

    public let dispatcher = GraphicsTranslationDispatcher.shared
    public let overrides = GraphicsOverrideManager.shared
    public let validator = GraphicsBaselineValidator.shared
    public let metalFX = MetalFXUpscalingPipeline.shared

    public init() {}
}
