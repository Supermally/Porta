import Foundation
import Metal

public struct ShaderCacheMetadata: Codable, Sendable {
    public let hash: String
    public let stage: String
    public let entryPoint: String
    public let shaderModel: String
    public let createdTimestamp: Double
}

public final class ShaderDiskCacheEngine: ObservableObject, @unchecked Sendable {
    public static let shared = ShaderDiskCacheEngine()

    @Published public var cacheHitsCount: UInt64 = 0
    @Published public var cacheMissesCount: UInt64 = 0
    @Published public var totalCachedShadersCount: Int = 0
    @Published public var diskCacheSizeBytes: UInt64 = 0

    private var memoryCache: [String: MTLLibrary] = [:]
    private let lock = NSLock()
    private let defaultDevice: MTLDevice?

    public var cacheDirectoryURL: URL {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MacGaming/Prefixes/default/metal_shader_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        inspectDiskCache()
    }

    public func inspectDiskCache() {
        if let files = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectoryURL.path) {
            var totalSize: UInt64 = 0
            for file in files {
                let filePath = cacheDirectoryURL.appendingPathComponent(file).path
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? UInt64 {
                    totalSize += size
                }
            }

            DispatchQueue.main.async {
                self.totalCachedShadersCount = files.filter { $0.hasSuffix(".metallib") }.count
                self.diskCacheSizeBytes = totalSize
            }
        }
    }

    public func queryOrCompile(analysis: ShaderAnalysisResult, rawBytecode: Data) -> MTLLibrary? {
        lock.lock()
        defer { lock.unlock() }

        // Tier 1: L1 In-Memory Fast Cache (<0.01ms hit)
        if let cached = memoryCache[analysis.contentHash] {
            DispatchQueue.main.async {
                self.cacheHitsCount += 1
            }
            return cached
        }

        // Tier 2: L2 Persistent Disk Cache (<0.2ms hit)
        let metallibFile = cacheDirectoryURL.appendingPathComponent("\(analysis.contentHash).metallib")
        if FileManager.default.fileExists(atPath: metallibFile.path),
           let device = defaultDevice,
           let diskLib = try? device.makeLibrary(URL: metallibFile) {
            memoryCache[analysis.contentHash] = diskLib
            DispatchQueue.main.async {
                self.cacheHitsCount += 1
            }
            return diskLib
        }

        // Cache Miss: Convert & Compile
        DispatchQueue.main.async {
            self.cacheMissesCount += 1
        }

        let output = MetalShaderConverter.shared.convertToMSL(analysis: analysis, rawBytecode: rawBytecode)
        if let newLib = output.library {
            memoryCache[analysis.contentHash] = newLib

            // Persist to L2 Disk Cache
            try? output.mslSource.write(
                to: cacheDirectoryURL.appendingPathComponent("\(analysis.contentHash).metal"),
                atomically: true,
                encoding: .utf8
            )

            let meta = ShaderCacheMetadata(
                hash: analysis.contentHash,
                stage: analysis.stage.rawValue,
                entryPoint: analysis.entryPoint,
                shaderModel: analysis.shaderModel,
                createdTimestamp: Date().timeIntervalSince1970
            )
            if let metaData = try? JSONEncoder().encode(meta) {
                try? metaData.write(to: cacheDirectoryURL.appendingPathComponent("\(analysis.contentHash).meta.json"))
            }

            DispatchQueue.main.async {
                self.totalCachedShadersCount += 1
            }
            return newLib
        }

        return nil
    }
}
