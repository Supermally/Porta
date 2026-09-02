import Foundation

public final class MetalFXEnvironmentBridge: Sendable {
    public static let shared = MetalFXEnvironmentBridge()

    public init() {}

    public func buildEnvironment(
        preset: MetalFXQualityPreset,
        targetWidth: Int = 2560,
        targetHeight: Int = 1440
    ) -> [String: String] {
        var env: [String: String] = [:]

        if preset == .off {
            env["METALFX_ENABLE"] = "0"
            return env
        }

        let (inW, inH) = preset.calculateInputResolution(targetWidth: targetWidth, targetHeight: targetHeight)

        env["METALFX_ENABLE"] = "1"
        env["METALFX_SCALE_PRESET"] = preset.rawValue.lowercased()
        env["METALFX_SCALE_FACTOR"] = String(format: "%.2f", preset.scaleFactor)
        env["METALFX_INPUT_WIDTH"] = "\(inW)"
        env["METALFX_INPUT_HEIGHT"] = "\(inH)"
        env["METALFX_OUTPUT_WIDTH"] = "\(targetWidth)"
        env["METALFX_OUTPUT_HEIGHT"] = "\(targetHeight)"
        env["METALFX_ENABLE_JITTER"] = "1"

        return env
    }
}
