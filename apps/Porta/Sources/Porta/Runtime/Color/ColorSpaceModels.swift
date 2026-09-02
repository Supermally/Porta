import Foundation
import CoreGraphics

public enum RuntimeColorSpaceType: String, CaseIterable, Codable, Identifiable, Sendable {
    case sdr_sRGB = "SDR (sRGB / Rec.709)"
    case sdr_displayP3 = "Wide Color SDR (Display P3)"
    case hdr10_PQ = "HDR10 (SMPTE ST 2084 / Rec.2020)"
    case hdr_scRGB_linear = "scRGB (Linear FP16)"
    case macOS_EDR_P3 = "macOS Extended Linear (Display P3 EDR)"

    public var id: String { rawValue }
}

public enum ColorGamutMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case sRGB = "sRGB (Standard)"
    case dciP3 = "Display P3 (Wide Color)"
    case rec2020 = "Rec.2020 (Ultra Wide HDR)"

    public var id: String { rawValue }
}

public struct GameHDRCalibrationProfile: Codable, Sendable {
    public var isHDREnabled: Bool
    public var targetColorSpace: RuntimeColorSpaceType
    public var colorGamut: ColorGamutMode
    public var paperWhiteNits: Double
    public var peakBrightnessNits: Double
    public var enableToneCurveClamping: Bool

    public init(
        isHDREnabled: Bool = false,
        targetColorSpace: RuntimeColorSpaceType = .sdr_sRGB,
        colorGamut: ColorGamutMode = .dciP3,
        paperWhiteNits: Double = 250.0,
        peakBrightnessNits: Double = 1600.0,
        enableToneCurveClamping: Bool = true
    ) {
        self.isHDREnabled = isHDREnabled
        self.targetColorSpace = targetColorSpace
        self.colorGamut = colorGamut
        self.paperWhiteNits = paperWhiteNits
        self.peakBrightnessNits = peakBrightnessNits
        self.enableToneCurveClamping = enableToneCurveClamping
    }
}
