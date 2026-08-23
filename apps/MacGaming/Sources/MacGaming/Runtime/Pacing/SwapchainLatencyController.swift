import Foundation

public final class SwapchainLatencyController: ObservableObject, @unchecked Sendable {
    public static let shared = SwapchainLatencyController()

    @Published public var isUltraLowLatencyModeEnabled: Bool = true
    @Published public var maxInFlightFramesCapped: Int = 1
    @Published public var estimatedInputLagReductionMs: Double = 8.5

    public init() {}

    public func setLowLatencyMode(enabled: Bool) {
        DispatchQueue.main.async {
            self.isUltraLowLatencyModeEnabled = enabled
            self.maxInFlightFramesCapped = enabled ? 1 : 2
            self.estimatedInputLagReductionMs = enabled ? 8.5 : 0.0
        }
    }
}
