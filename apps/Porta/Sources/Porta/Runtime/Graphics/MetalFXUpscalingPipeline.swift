import Foundation
import Metal

public struct MetalFXConfiguration: Sendable {
    public let mode: MetalFXMode
    public let inputWidth: Int
    public let inputHeight: Int
    public let outputWidth: Int
    public let outputHeight: Int
    public let sharpness: Float
}

public final class MetalFXUpscalingPipeline: ObservableObject, @unchecked Sendable {
    public static let shared = MetalFXUpscalingPipeline()

    @Published public var activeMode: MetalFXMode = .off
    @Published public var scalingFactor: Double = 1.0
    @Published public var isNeuralEngineAccelerated: Bool = true

    public init() {}

    public func configureUpscaling(mode: MetalFXMode, inputRes: (width: Int, height: Int), outputRes: (width: Int, height: Int)) -> [String: String] {
        var env: [String: String] = [:]
        let factor = Double(outputRes.width) / max(1.0, Double(inputRes.width))

        DispatchQueue.main.async {
            self.activeMode = mode
            self.scalingFactor = factor
        }

        switch mode {
        case .off:
            env["METALFX_ENABLE"] = "0"
        case .spatial:
            env["METALFX_ENABLE"] = "1"
            env["METALFX_MODE"] = "spatial"
            env["METALFX_INPUT_WIDTH"] = "\(inputRes.width)"
            env["METALFX_INPUT_HEIGHT"] = "\(inputRes.height)"
            env["METALFX_OUTPUT_WIDTH"] = "\(outputRes.width)"
            env["METALFX_OUTPUT_HEIGHT"] = "\(outputRes.height)"
        case .temporal:
            env["METALFX_ENABLE"] = "1"
            env["METALFX_MODE"] = "temporal"
            env["METALFX_INPUT_WIDTH"] = "\(inputRes.width)"
            env["METALFX_INPUT_HEIGHT"] = "\(inputRes.height)"
            env["METALFX_OUTPUT_WIDTH"] = "\(outputRes.width)"
            env["METALFX_OUTPUT_HEIGHT"] = "\(outputRes.height)"
            env["METALFX_ENABLE_JITTER"] = "1"
        }

        return env
    }
}
