import Foundation

public final class SteamIntegrationService: ObservableObject, @unchecked Sendable {
    public static let shared = SteamIntegrationService()

    public let wow64 = UnifiedWoW64ArchitectureEngine.shared
    public let orchestrator = SteamProcessOrchestrator.shared
    public let ipc = SteamIPCBridgeManager.shared
    public let prefixBuilder = SteamWoW64PrefixBuilder.shared

    public init() {}
}
