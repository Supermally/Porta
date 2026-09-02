import Foundation

public struct FramePacingTelemetrySnapshot: Sendable {
    public let averageFps: Double
    public let onePercentLowFps: Double
    public let zeroPointOnePercentLowFps: Double
    public let frameTimeVarianceMs: Double
    public let estimatedInputLatencyMs: Double
}

public final class FrameTelemetryEngine: ObservableObject, @unchecked Sendable {
    public static let shared = FrameTelemetryEngine()

    @Published public var currentAverageFps: Double = 120.0
    @Published public var currentOnePercentLowFps: Double = 114.2
    @Published public var currentZeroPointOnePercentLowFps: Double = 98.6
    @Published public var currentVarianceMs: Double = 0.12
    @Published public var currentInputLatencyMs: Double = 9.4

    private var frameTimeHistoryMs: [Double] = []
    private let capacity: Int = 1000 // 1000-frame rolling window
    private let lock = NSLock()

    public init() {
        // Pre-populate with ideal 120Hz frame times
        for _ in 0..<120 {
            frameTimeHistoryMs.append(8.33)
        }
    }

    public func recordFrame(durationMs: Double) {
        lock.lock()
        defer { lock.unlock() }

        frameTimeHistoryMs.append(durationMs)
        if frameTimeHistoryMs.count > capacity {
            frameTimeHistoryMs.removeFirst()
        }

        recalculateMetrics()
    }

    private func recalculateMetrics() {
        guard !frameTimeHistoryMs.isEmpty else { return }

        let count = Double(frameTimeHistoryMs.count)
        let totalDuration = frameTimeHistoryMs.reduce(0, +)
        let avgDuration = totalDuration / count
        let avgFps = avgDuration > 0 ? (1000.0 / avgDuration) : 0.0

        // Variance
        let varianceSum = frameTimeHistoryMs.map { pow($0 - avgDuration, 2) }.reduce(0, +)
        let stdDevMs = sqrt(varianceSum / count)

        // Percentiles (sort frame times descending: slowest frames first)
        let sortedDesc = frameTimeHistoryMs.sorted(by: >)
        let onePctIndex = min(sortedDesc.count - 1, max(0, Int(Double(sortedDesc.count) * 0.01)))
        let zeroOnePctIndex = min(sortedDesc.count - 1, max(0, Int(Double(sortedDesc.count) * 0.001)))

        let onePctSlowestFrameMs = sortedDesc[onePctIndex]
        let zeroOnePctSlowestFrameMs = sortedDesc[zeroOnePctIndex]

        let onePctLowFps = onePctSlowestFrameMs > 0 ? (1000.0 / onePctSlowestFrameMs) : avgFps
        let zeroOnePctLowFps = zeroOnePctSlowestFrameMs > 0 ? (1000.0 / zeroOnePctSlowestFrameMs) : avgFps
        let inputLagMs = avgDuration + (stdDevMs * 1.5)

        DispatchQueue.main.async {
            self.currentAverageFps = avgFps
            self.currentOnePercentLowFps = onePctLowFps
            self.currentZeroPointOnePercentLowFps = zeroOnePctLowFps
            self.currentVarianceMs = stdDevMs
            self.currentInputLatencyMs = inputLagMs
        }
    }
}
