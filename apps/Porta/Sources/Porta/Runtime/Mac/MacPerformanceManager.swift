import Foundation
import Metal

public final class MacPerformanceManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacPerformanceManager()

    @Published public var gpuUtilizationPct: Int = 0
    @Published public var cpuUtilizationPct: Int = 0
    @Published public var thermalStateDescription: String = "Nominal"
    @Published public var isThrottling: Bool = false
    @Published public var currentFpsEstimate: Int = 120

    private var telemetryTimer: Timer?

    public init() {
        startTelemetryLoop()
    }

    public func startTelemetryLoop() {
        self.telemetryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.samplePerformanceMetrics()
        }
    }

    public func samplePerformanceMetrics() {
        // 1. Thermal State
        let thermal = ProcessInfo.processInfo.thermalState
        let desc: String
        let throttling: Bool
        switch thermal {
        case .nominal:
            desc = "Nominal (Cool)"
            throttling = false
        case .fair:
            desc = "Fair (Normal Gaming Load)"
            throttling = false
        case .serious:
            desc = "Serious (Approaching Thermal Ceiling)"
            throttling = true
        case .critical:
            desc = "Critical (Thermal Throttling Active)"
            throttling = true
        @unknown default:
            desc = "Normal"
            throttling = false
        }

        // 2. Hardware telemetry updates
        DispatchQueue.main.async {
            self.thermalStateDescription = desc
            self.isThrottling = throttling
        }
    }
}
