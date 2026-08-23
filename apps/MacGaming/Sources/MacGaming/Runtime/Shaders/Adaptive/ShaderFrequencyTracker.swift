import Foundation

public enum ShaderFrequencyTier: String, Codable, Sendable {
    case common = "Common / Hot"
    case frequent = "Frequent / Warm"
    case rare = "Rare / Cold"
}

public struct ShaderUsageMetric: Codable, Sendable {
    public let hash: String
    public var invocationCount: UInt64
    public var lastSeenTimestamp: Double
    public var tier: ShaderFrequencyTier
}

public final class ShaderFrequencyTracker: ObservableObject, @unchecked Sendable {
    public static let shared = ShaderFrequencyTracker()

    @Published public var commonShadersCount: Int = 0
    @Published public var frequentShadersCount: Int = 0
    @Published public var rareShadersCount: Int = 0

    private var trackedShaders: [String: ShaderUsageMetric] = [:]
    private let lock = NSLock()

    public init() {}

    public func recordInvocation(hash: String) {
        lock.lock()
        defer { lock.unlock() }

        var metric = trackedShaders[hash] ?? ShaderUsageMetric(
            hash: hash,
            invocationCount: 0,
            lastSeenTimestamp: Date().timeIntervalSince1970,
            tier: .rare
        )

        metric.invocationCount += 1
        metric.lastSeenTimestamp = Date().timeIntervalSince1970

        // Classify dynamic heat tier
        if metric.invocationCount >= 50 {
            metric.tier = .common
        } else if metric.invocationCount >= 10 {
            metric.tier = .frequent
        } else {
            metric.tier = .rare
        }

        trackedShaders[hash] = metric
        updateCounts()
    }

    public func getTier(for hash: String) -> ShaderFrequencyTier {
        lock.lock()
        defer { lock.unlock() }
        return trackedShaders[hash]?.tier ?? .rare
    }

    public func allMetrics() -> [ShaderUsageMetric] {
        lock.lock()
        defer { lock.unlock() }
        return Array(trackedShaders.values)
    }

    public func restoreMetrics(_ metrics: [ShaderUsageMetric]) {
        lock.lock()
        defer { lock.unlock() }
        for m in metrics {
            trackedShaders[m.hash] = m
        }
        updateCounts()
    }

    private func updateCounts() {
        var common = 0
        var frequent = 0
        var rare = 0
        for (_, val) in trackedShaders {
            switch val.tier {
            case .common: common += 1
            case .frequent: frequent += 1
            case .rare: rare += 1
            }
        }

        DispatchQueue.main.async {
            self.commonShadersCount = common
            self.frequentShadersCount = frequent
            self.rareShadersCount = rare
        }
    }
}
