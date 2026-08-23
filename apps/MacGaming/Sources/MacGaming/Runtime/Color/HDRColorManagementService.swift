import Foundation

public final class HDRColorManagementService: ObservableObject, @unchecked Sendable {
    public static let shared = HDRColorManagementService()

    public let transformer = ColorSpaceTransformer.shared
    public let calibrator = DisplayEDRCalibrator.shared
    public let store = GameHDRProfileStore.shared

    public init() {}
}
