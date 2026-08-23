import Foundation

public struct GameAdaptiveProfileData: Codable, Sendable {
    public let gameId: String
    public var commonShaders: [String]
    public var commonPipelines: [String]
    public var rarePipelines: [String]
    public var metrics: [ShaderUsageMetric]
    public var lastUpdatedTimestamp: Double
}

public final class GameAdaptiveShaderProfileStore: Sendable {
    public static let shared = GameAdaptiveShaderProfileStore()

    public init() {}

    public func profileURL(for gameId: String) -> URL {
        let prefixDir = PrefixManager.shared.prefixURL(for: gameId, isolated: false)
        return prefixDir.appendingPathComponent("adaptive_shader_profile.json")
    }

    public func saveProfile(gameId: String, common: [String], commonPipelined: [String], rare: [String], metrics: [ShaderUsageMetric]) {
        let data = GameAdaptiveProfileData(
            gameId: gameId,
            commonShaders: common,
            commonPipelines: commonPipelined,
            rarePipelines: rare,
            metrics: metrics,
            lastUpdatedTimestamp: Date().timeIntervalSince1970
        )

        let url = profileURL(for: gameId)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: url)
        }
    }

    public func loadProfile(for gameId: String) -> GameAdaptiveProfileData? {
        let url = profileURL(for: gameId)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(GameAdaptiveProfileData.self, from: data) else {
            return nil
        }
        return decoded
    }
}
