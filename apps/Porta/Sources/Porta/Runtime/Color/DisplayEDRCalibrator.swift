import Foundation
import AppKit
import QuartzCore

public final class DisplayEDRCalibrator: ObservableObject, @unchecked Sendable {
    public static let shared = DisplayEDRCalibrator()

    @Published public var currentEDRHeadroom: Double = 1.0
    @Published public var isEDRSupported: Bool = false
    @Published public var estimatedPeakNits: Double = 500.0
    @Published public var activeDisplayColorSpaceName: String = "Display P3"

    public init() {
        calibrateCurrentDisplay()
    }

    public func calibrateCurrentDisplay() {
        if let mainScreen = NSScreen.main {
            let maxEDR = mainScreen.maximumExtendedDynamicRangeColorComponentValue
            let isSupported = maxEDR > 1.0
            let peakNits = isSupported ? (maxEDR * 100.0 * 4.0) : 500.0

            DispatchQueue.main.async {
                self.currentEDRHeadroom = maxEDR
                self.isEDRSupported = isSupported
                self.estimatedPeakNits = min(1600.0, max(500.0, peakNits))
                self.activeDisplayColorSpaceName = mainScreen.colorSpace?.localizedName ?? "Display P3"
            }
        }
    }

    public func configureHDRLayer(_ layer: CAMetalLayer, enableHDR: Bool) {
        if enableHDR && isEDRSupported {
            layer.wantsExtendedDynamicRangeContent = true
            layer.pixelFormat = .rgba16Float
            if let cs = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3) {
                layer.colorspace = cs
            }
        } else {
            layer.wantsExtendedDynamicRangeContent = false
            layer.pixelFormat = .bgra8Unorm_srgb
            if let cs = CGColorSpace(name: CGColorSpace.displayP3) {
                layer.colorspace = cs
            }
        }
    }
}
