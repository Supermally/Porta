import Foundation

public enum ResourceAccessType: UInt8, Sendable {
    case read = 0
    case write = 1
    case readWrite = 2
}

public enum HazardType: String, Sendable {
    case none = "No Hazard"
    case raw = "Read-After-Write (RAW)"
    case war = "Write-After-Read (WAR)"
    case waw = "Write-After-Write (WAW)"
}

public struct ResourceAccessRecord: Sendable {
    public let resourceId: UInt64
    public let accessType: ResourceAccessType
    public let frameIndex: UInt64
    public let isHostVisible: Bool
    public let isImmediateCPUReadback: Bool
}

public final class SyncDependencyGraphAnalyzer: ObservableObject, @unchecked Sendable {
    public static let shared = SyncDependencyGraphAnalyzer()

    @Published public var totalDependenciesEvaluated: UInt64 = 0
    @Published public var safeDeferralsCount: UInt64 = 0
    @Published public var trueHazardsCount: UInt64 = 0

    private var activeResourceAccesses: [UInt64: ResourceAccessRecord] = [:]
    private let lock = NSLock()

    public init() {}

    public func evaluateDependency(record: ResourceAccessRecord) -> (canDefer: Bool, hazard: HazardType) {
        lock.lock()
        defer { lock.unlock() }

        totalDependenciesEvaluated += 1

        guard let previous = activeResourceAccesses[record.resourceId] else {
            // No prior access in current tracking window -> Safe
            activeResourceAccesses[record.resourceId] = record
            safeDeferralsCount += 1
            return (canDefer: true, hazard: .none)
        }

        // Check for immediate CPU readback requirements (e.g. screenshots, queries)
        if record.isImmediateCPUReadback {
            activeResourceAccesses[record.resourceId] = record
            trueHazardsCount += 1
            return (canDefer: false, hazard: .raw)
        }

        // Check multi-buffering (if access happens on a future frame or ring buffer)
        if record.frameIndex > previous.frameIndex + 1 {
            // Buffer ring-isolated -> Safe to defer wait
            activeResourceAccesses[record.resourceId] = record
            safeDeferralsCount += 1
            return (canDefer: true, hazard: .none)
        }

        // Hazard identification
        let hazard: HazardType
        if previous.accessType == .write && record.accessType == .read {
            hazard = .raw
        } else if previous.accessType == .read && record.accessType == .write {
            hazard = .war
        } else if previous.accessType == .write && record.accessType == .write {
            hazard = .waw
        } else {
            hazard = .none
        }

        activeResourceAccesses[record.resourceId] = record

        if hazard == .none || (record.isHostVisible && !record.isImmediateCPUReadback) {
            safeDeferralsCount += 1
            return (canDefer: true, hazard: hazard)
        } else {
            trueHazardsCount += 1
            return (canDefer: false, hazard: hazard)
        }
    }

    public func resetTracking() {
        lock.lock()
        defer { lock.unlock() }
        activeResourceAccesses.removeAll()
    }
}
