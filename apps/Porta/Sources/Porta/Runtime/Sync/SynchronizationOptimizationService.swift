import Foundation

public final class SynchronizationOptimizationService: ObservableObject, @unchecked Sendable {
    public static let shared = SynchronizationOptimizationService()

    public let analyzer = SyncDependencyGraphAnalyzer.shared
    public let timeline = TimelineFenceCoordinator.shared
    public let elision = SyncWaitElisionEngine.shared
    public let batcher = CommandSubmissionBatcher.shared
    public let validator = SyncCorrectnessValidator.shared

    public init() {}
}
