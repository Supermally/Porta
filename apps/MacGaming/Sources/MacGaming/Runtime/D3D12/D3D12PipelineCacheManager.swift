import Foundation
import Metal

public struct PipelineCacheEntry: Sendable {
    public let hash: String
    public let byteSize: Int
    public let isPrecompiled: Bool
}

public final class D3D12PipelineCacheManager: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12PipelineCacheManager()

    @Published public var cachedPipelinesCount: Int = 0
    @Published public var diskCacheSizeBytes: UInt64 = 0
    @Published public var runtimeStuttersEliminated: Int = 0

    private var inMemoryPSOCache: [String: MTLRenderPipelineState] = [:]
    private let lock = NSLock()

    public init() {
        inspectDiskCache()
    }

    public func inspectDiskCache() {
        let cacheDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MacGaming/Prefixes/default/metal_pso_cache")
        if let files = try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path) {
            var totalSize: UInt64 = 0
            for file in files {
                let filePath = cacheDir.appendingPathComponent(file).path
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? UInt64 {
                    totalSize += size
                }
            }

            DispatchQueue.main.async {
                self.cachedPipelinesCount = files.count
                self.diskCacheSizeBytes = totalSize
                self.runtimeStuttersEliminated = files.count
            }
        }
    }

    public func registerPipelineState(hash: String, pso: MTLRenderPipelineState) {
        lock.lock()
        defer { lock.unlock() }

        inMemoryPSOCache[hash] = pso
        DispatchQueue.main.async {
            self.cachedPipelinesCount = self.inMemoryPSOCache.count
            self.runtimeStuttersEliminated += 1
        }
    }
}
