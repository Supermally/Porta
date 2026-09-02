import Foundation

public enum MetalFXQualityPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case off = "Off"
    case performance = "Performance"
    case balanced = "Balanced"
    case quality = "Quality"

    public var id: String { rawValue }

    public var scaleFactor: Double {
        switch self {
        case .off: return 1.0
        case .quality: return 1.5
        case .balanced: return 1.7
        case .performance: return 2.0
        }
    }

    public var inputResolutionScale: Double {
        return 1.0 / scaleFactor
    }

    public func calculateInputResolution(targetWidth: Int, targetHeight: Int) -> (width: Int, height: Int) {
        if self == .off {
            return (targetWidth, targetHeight)
        }
        let inW = Int(Double(targetWidth) * inputResolutionScale)
        let inH = Int(Double(targetHeight) * inputResolutionScale)
        // Ensure even pixel dimensions
        return ((inW / 2) * 2, (inH / 2) * 2)
    }
}
