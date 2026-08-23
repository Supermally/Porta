import Foundation
import AppKit
import CoreGraphics

public final class MacDisplayManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacDisplayManager()

    @Published public var primaryDisplayId: CGDirectDisplayID = CGMainDisplayID()
    @Published public var refreshRateHz: Double = 60.0
    @Published public var isProMotionActive: Bool = false
    @Published public var isEDRSupported: Bool = false
    @Published public var maxEDRPotential: Double = 1.0
    @Published public var currentResolution: String = "1920x1080"

    public init() {
        inspectDisplays()
    }

    public func inspectDisplays() {
        let mainDisplay = CGMainDisplayID()
        self.primaryDisplayId = mainDisplay

        if let mode = CGDisplayCopyDisplayMode(mainDisplay) {
            let width = mode.width
            let height = mode.height
            var refresh = mode.refreshRate
            if refresh == 0 {
                // If ProMotion, fetch maximum available refresh rate
                if let screen = NSScreen.main {
                    refresh = Double(screen.maximumExtendedDynamicRangeColorComponentValue > 1.0 ? 120 : 60)
                } else {
                    refresh = 60.0
                }
            }

            self.refreshRateHz = refresh
            self.isProMotionActive = refresh >= 119.0
            self.currentResolution = "\(width)x\(height)"
        }

        if let screen = NSScreen.main {
            self.maxEDRPotential = screen.maximumExtendedDynamicRangeColorComponentValue
            self.isEDRSupported = screen.maximumExtendedDynamicRangeColorComponentValue > 1.0
        }
    }

    public func optimalDisplayArguments(targetFps: Int, enableHdr: Bool) -> [String] {
        var args: [String] = []
        if isProMotionActive && targetFps >= 120 {
            args.append("-refresh")
            args.append("120")
        } else if targetFps > 0 {
            args.append("-refresh")
            args.append("\(targetFps)")
        }

        if enableHdr && isEDRSupported {
            args.append("-hdr")
            args.append("-colormode=edr16")
        }

        return args
    }
}
