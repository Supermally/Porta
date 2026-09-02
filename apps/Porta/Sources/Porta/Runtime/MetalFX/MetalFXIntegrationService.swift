import Foundation

public final class MetalFXIntegrationService: ObservableObject, @unchecked Sendable {
    public static let shared = MetalFXIntegrationService()

    public let detector = MetalFXCompatibilityDetector.shared
    public let scaler = MetalFXRuntimeScaler.shared
    public let bridge = MetalFXEnvironmentBridge.shared

    @Published public var currentPreset: MetalFXQualityPreset = .quality

    public init() {}
}
