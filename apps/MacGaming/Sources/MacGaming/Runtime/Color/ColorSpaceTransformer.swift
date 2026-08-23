import Foundation

public final class ColorSpaceTransformer: Sendable {
    public static let shared = ColorSpaceTransformer()

    // SMPTE ST 2084 (PQ) constants
    private let m1 = 2610.0 / 16384.0 // ~0.1593017578125
    private let m2 = (2523.0 / 4096.0) * 128.0 // ~78.84375
    private let c1 = 3424.0 / 4096.0 // ~0.8359375
    private let c2 = (2413.0 / 4096.0) * 32.0 // ~18.8515625
    private let c3 = (2392.0 / 4096.0) * 32.0 // ~18.6875

    public init() {}

    public func convertPQToLinearNits(pqValue: Double) -> Double {
        guard pqValue > 0.0 else { return 0.0 }
        let N = max(0.0, min(1.0, pqValue))
        let N_pow = pow(N, 1.0 / m2)
        let num = max(N_pow - c1, 0.0)
        let den = c2 - (c3 * N_pow)
        guard den > 0.0 else { return 10000.0 }
        let linearNormalized = pow(num / den, 1.0 / m1)
        return linearNormalized * 10000.0 // 0 to 10,000 Nits
    }

    public func mapNitsToEDRFloat(nits: Double, paperWhiteNits: Double = 250.0, displayMaxEDR: Double = 3.5) -> Double {
        let referenceSDRNits = 80.0
        let linearFloat = nits / referenceSDRNits
        let headroomAllowed = displayMaxEDR * (paperWhiteNits / referenceSDRNits)
        return min(linearFloat, headroomAllowed)
    }

    public func transformRec2020ToDisplayP3(r: Double, g: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        // Rec.2020 to Display P3 3x3 Matrix Transformation
        let p3_r = (1.2249 * r) - (0.2247 * g) - (0.0002 * b)
        let p3_g = (-0.0420 * r) + (1.0419 * g) + (0.0001 * b)
        let p3_b = (-0.0197 * r) - (0.0786 * g) + (1.0983 * b)
        return (max(0.0, p3_r), max(0.0, p3_g), max(0.0, p3_b))
    }
}
