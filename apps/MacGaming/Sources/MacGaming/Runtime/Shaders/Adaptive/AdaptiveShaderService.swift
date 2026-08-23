import Foundation

public final class AdaptiveShaderService: ObservableObject, @unchecked Sendable {
    public static let shared = AdaptiveShaderService()

    public let tracker = ShaderFrequencyTracker.shared
    public let sceneProfiler = GameSceneProfiler.shared
    public let store = GameAdaptiveShaderProfileStore.shared
    public let orchestrator = AdaptivePreWarmOrchestrator.shared

    public init() {}
}
