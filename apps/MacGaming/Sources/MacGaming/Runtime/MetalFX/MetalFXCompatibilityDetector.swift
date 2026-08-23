import Foundation
import Metal

public enum MetalFXExecutionMode: String, Sendable {
    case disabled = "Disabled / Bypassed"
    case spatial = "Spatial (Edge-Directed Super-Resolution)"
    case temporal = "Temporal (Neural Engine Super-Resolution)"
}

public struct RenderTargetCompatibilityReport: Sendable {
    public let executionMode: MetalFXExecutionMode
    public let isEligible: Bool
    public let colorFormatValid: Bool
    public let depthFormatValid: Bool
    public let motionVectorsPresent: Bool
    public let diagnosticReason: String
}

public final class MetalFXCompatibilityDetector: ObservableObject, @unchecked Sendable {
    public static let shared = MetalFXCompatibilityDetector()

    @Published public var lastReport: RenderTargetCompatibilityReport?
    @Published public var supportedColorFormatsCount: Int = 3

    public init() {}

    public func evaluateCompatibility(
        colorFormat: MTLPixelFormat,
        depthFormat: MTLPixelFormat? = nil,
        motionVectorFormat: MTLPixelFormat? = nil,
        hasCameraJitter: Bool = false
    ) -> RenderTargetCompatibilityReport {
        // 1. Color Buffer Format Validation
        let validColor: Bool
        switch colorFormat {
        case .rgba16Float, .bgra8Unorm, .bgra8Unorm_srgb, .rgba8Unorm, .rgba8Unorm_srgb:
            validColor = true
        default:
            validColor = false
        }

        guard validColor else {
            let rep = RenderTargetCompatibilityReport(
                executionMode: .disabled,
                isEligible: false,
                colorFormatValid: false,
                depthFormatValid: false,
                motionVectorsPresent: false,
                diagnosticReason: "Unsupported color texture pixel format (\(colorFormat.rawValue)). MetalFX safely bypassed."
            )
            updateState(rep)
            return rep
        }

        // 2. Motion Vector & Depth Buffer Validation
        let validDepth = (depthFormat == .depth32Float || depthFormat == .depth24Unorm_stencil8 || depthFormat == .depth32Float_stencil8)
        let validMV = (motionVectorFormat == .rg16Float || motionVectorFormat == .rg32Float)

        if validDepth && validMV && hasCameraJitter {
            let rep = RenderTargetCompatibilityReport(
                executionMode: .temporal,
                isEligible: true,
                colorFormatValid: true,
                depthFormatValid: true,
                motionVectorsPresent: true,
                diagnosticReason: "Validated color, depth, motion vectors, and jitter matrix. Engaged Temporal MetalFX."
            )
            updateState(rep)
            return rep
        } else {
            // Fallback to Spatial MetalFX
            let rep = RenderTargetCompatibilityReport(
                executionMode: .spatial,
                isEligible: true,
                colorFormatValid: true,
                depthFormatValid: validDepth,
                motionVectorsPresent: false,
                diagnosticReason: "Motion vectors or jitter absent. Engaged conservative Spatial MetalFX."
            )
            updateState(rep)
            return rep
        }
    }

    private func updateState(_ report: RenderTargetCompatibilityReport) {
        DispatchQueue.main.async {
            self.lastReport = report
        }
    }
}
