import Foundation
import CryptoKit

public enum ShaderStage: String, Codable, Sendable {
    case vertex = "Vertex"
    case fragment = "Fragment / Pixel"
    case compute = "Compute"
    case mesh = "Mesh"
    case amplification = "Amplification / Task"
    case raytracing = "Raytracing"
}

public struct ShaderAnalysisResult: Sendable {
    public let stage: ShaderStage
    public let entryPoint: String
    public let shaderModel: String
    public let contentHash: String
    public let bytecodeSizeBytes: Int
    public let usesArgumentBuffers: Bool
}

public final class ShaderAnalyzer: Sendable {
    public static let shared = ShaderAnalyzer()

    public init() {}

    public func analyzeBytecode(data: Data, entryPoint: String = "main", stage: ShaderStage = .fragment, shaderModel: String = "6.6") -> ShaderAnalysisResult {
        // Compute SHA-256 content hash
        var hasher = SHA256()
        hasher.update(data: data)
        hasher.update(data: Data(entryPoint.utf8))
        hasher.update(data: Data(stage.rawValue.utf8))
        hasher.update(data: Data(shaderModel.utf8))
        let digest = hasher.finalize()
        let hashString = digest.map { String(format: "%02x", $0) }.joined()

        let isLargeOrModern = data.count > 1024 || shaderModel >= "6.0"

        return ShaderAnalysisResult(
            stage: stage,
            entryPoint: entryPoint,
            shaderModel: shaderModel,
            contentHash: hashString,
            bytecodeSizeBytes: data.count,
            usesArgumentBuffers: isLargeOrModern
        )
    }
}
