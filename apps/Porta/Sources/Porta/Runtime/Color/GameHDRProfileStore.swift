import Foundation

public final class GameHDRProfileStore: Sendable {
    public static let shared = GameHDRProfileStore()

    public init() {}

    public func profileURL(for gameId: String) -> URL {
        let prefixDir = PrefixManager.shared.prefixURL(for: gameId, isolated: false)
        return prefixDir.appendingPathComponent("hdr_profile.json")
    }

    public func saveProfile(_ profile: GameHDRCalibrationProfile, for gameId: String) {
        let url = profileURL(for: gameId)
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: url)
        }
    }

    public func loadProfile(for gameId: String) -> GameHDRCalibrationProfile {
        let url = profileURL(for: gameId)
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let profile = try? JSONDecoder().decode(GameHDRCalibrationProfile.self, from: data) {
            return profile
        }
        return GameHDRCalibrationProfile()
    }
}
