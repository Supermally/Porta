import Foundation
import AppKit
import QuartzCore

public final class ProMotionDisplaySynchronizer: ObservableObject, @unchecked Sendable {
    public static let shared = ProMotionDisplaySynchronizer()

    @Published public var currentRefreshRateHz: Int = 120
    @Published public var isProMotionActive: Bool = true
    @Published public var isVariableRefreshRateSupported: Bool = true
    @Published public var targetFrameIntervalMs: Double = 8.33

    public init() {
        detectMainDisplayCapabilities()
    }

    public func detectMainDisplayCapabilities() {
        if let mainScreen = NSScreen.main {
            let maxHz = mainScreen.maximumFramesPerSecond
            let isProMotion = maxHz >= 120

            DispatchQueue.main.async {
                self.currentRefreshRateHz = maxHz > 0 ? maxHz : 120
                self.isProMotionActive = isProMotion
                self.isVariableRefreshRateSupported = isProMotion
                self.targetFrameIntervalMs = 1000.0 / Double(self.currentRefreshRateHz)
            }
        }
    }

    public func configureMetalLayer(_ layer: CAMetalLayer, lowLatencyMode: Bool) {
        layer.maximumDrawableCount = lowLatencyMode ? 2 : 3
        layer.presentsWithTransaction = false
        layer.displaySyncEnabled = true
    }
}
