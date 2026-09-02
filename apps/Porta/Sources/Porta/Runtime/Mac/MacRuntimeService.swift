import Foundation

public final class MacRuntimeService: ObservableObject, @unchecked Sendable {
    public static let shared = MacRuntimeService()

    public let memory = MacMemoryManager.shared
    public let display = MacDisplayManager.shared
    public let input = MacInputManager.shared
    public let audio = MacAudioManager.shared
    public let process = MacProcessManager.shared
    public let detection = MacGameDetectionEngine.shared
    public let performance = MacPerformanceManager.shared

    public init() {}
}
