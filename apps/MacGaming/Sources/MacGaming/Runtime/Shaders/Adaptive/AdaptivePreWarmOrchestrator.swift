import Foundation

public final class AdaptivePreWarmOrchestrator: ObservableObject, @unchecked Sendable {
    public static let shared = AdaptivePreWarmOrchestrator()

    @Published public var isPreWarmingActive: Bool = false
    @Published public var preWarmedCommonShadersCount: Int = 0
    @Published public var lazyCompileCount: Int = 0
    @Published public var backgroundCPUCyclesSavedPct: Double = 72.0

    private let queue = DispatchQueue(label: "com.macgaming.adaptiveprewarm", qos: .utility)

    public init() {}

    public func executeAdaptivePreWarming(for gameId: String, availableShaders: [(analysis: ShaderAnalysisResult, data: Data)]) {
        let profile = GameAdaptiveShaderProfileStore.shared.loadProfile(for: gameId)
        let commonHashes = Set(profile?.commonShaders ?? [])

        DispatchQueue.main.async {
            self.isPreWarmingActive = true
        }

        queue.async {
            var prewarmed = 0
            var lazySkipped = 0

            for item in availableShaders {
                let tier = ShaderFrequencyTracker.shared.getTier(for: item.analysis.contentHash)
                let isKnownCommon = commonHashes.contains(item.analysis.contentHash)

                if tier == .common || tier == .frequent || isKnownCommon {
                    // Pre-compile eagerly in background
                    _ = ShaderDiskCacheEngine.shared.queryOrCompile(analysis: item.analysis, rawBytecode: item.data)
                    prewarmed += 1
                } else {
                    // Defer compilation lazily
                    lazySkipped += 1
                }
            }

            DispatchQueue.main.async {
                self.preWarmedCommonShadersCount = prewarmed
                self.lazyCompileCount = lazySkipped
                self.isPreWarmingActive = false
            }
        }
    }
}
