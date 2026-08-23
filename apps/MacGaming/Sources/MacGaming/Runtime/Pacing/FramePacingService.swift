import Foundation

public final class FramePacingService: ObservableObject, @unchecked Sendable {
    public static let shared = FramePacingService()

    public let display = ProMotionDisplaySynchronizer.shared
    public let governor = FramePacingGovernor.shared
    public let latency = SwapchainLatencyController.shared
    public let telemetry = FrameTelemetryEngine.shared

    public init() {}
}
