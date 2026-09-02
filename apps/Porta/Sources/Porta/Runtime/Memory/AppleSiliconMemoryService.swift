import Foundation

public final class AppleSiliconMemoryService: ObservableObject, @unchecked Sendable {
    public static let shared = AppleSiliconMemoryService()

    public let heap = UnifiedMemoryHeapAllocator.shared
    public let tileCache = TileMemoryCacheManager.shared
    public let residency = ResourceResidencyTracker.shared
    public let sync = UnifiedSyncCoordinator.shared
    public let governor = MemoryPressureGovernor.shared
    public let benchmark = MemoryOptimizationBenchmark.shared

    public init() {}
}
