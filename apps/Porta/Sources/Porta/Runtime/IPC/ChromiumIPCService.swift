import Foundation

public final class ChromiumIPCService: ObservableObject, @unchecked Sendable {
    public static let shared = ChromiumIPCService()

    public let tree = ChromiumProcessTreeManager.shared
    public let mojo = MojoNamedPipeRouter.shared
    public let shm = CrossProcessSharedMemoryEngine.shared
    public let sync = ProcessHandleSyncCoordinator.shared

    public init() {}
}
