import Foundation

public final class ShaderPreWarmQueue: ObservableObject, @unchecked Sendable {
    public static let shared = ShaderPreWarmQueue()

    @Published public var isPreWarming: Bool = false
    @Published public var preWarmedShadersCount: Int = 0
    @Published public var pendingShadersCount: Int = 0

    private let queue = DispatchQueue(label: "com.macgaming.shaderprewarm", qos: .utility)

    public init() {}

    public func enqueueShadersForPreWarming(_ items: [(analysis: ShaderAnalysisResult, data: Data)]) {
        DispatchQueue.main.async {
            self.pendingShadersCount += items.count
            self.isPreWarming = true
        }

        queue.async {
            for item in items {
                _ = ShaderDiskCacheEngine.shared.queryOrCompile(analysis: item.analysis, rawBytecode: item.data)
                DispatchQueue.main.async {
                    self.preWarmedShadersCount += 1
                    self.pendingShadersCount = max(0, self.pendingShadersCount - 1)
                }
            }

            DispatchQueue.main.async {
                self.isPreWarming = false
            }
        }
    }
}
