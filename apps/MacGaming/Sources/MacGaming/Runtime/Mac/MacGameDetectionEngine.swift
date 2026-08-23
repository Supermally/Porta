import Foundation

public struct DetectedGameSignature: Sendable {
    public let title: String
    public let is64Bit: Bool
    public let primaryRenderer: GraphicsBackend
    public let detectedEngine: String
    public let antiCheatName: String?
    public let recommendedSync: SyncBackend
    public let recommendedMetalFX: MetalFXMode
}

public final class MacGameDetectionEngine: Sendable {
    public static let shared = MacGameDetectionEngine()

    public init() {}

    public func analyzeExecutable(at path: String) -> DetectedGameSignature {
        let filename = (path as NSString).lastPathComponent.lowercased()
        let directory = (path as NSString).deletingLastPathComponent.lowercased()

        let is64Bit = true
        var renderer: GraphicsBackend = .d3dmetal
        var engine = "Custom Native Engine"
        var antiCheat: String? = nil
        var sync: SyncBackend = .esync
        var metalFx: MetalFXMode = .off

        // 1. Anti-Cheat Signatures
        if filename.contains("easyanticheat") || directory.contains("easyanticheat") {
            antiCheat = "Easy Anti-Cheat (Kernel Driver)"
        } else if filename.contains("battleye") || directory.contains("battleye") {
            antiCheat = "BattlEye (Kernel Driver)"
        } else if filename.contains("vanguard") || directory.contains("vgk") {
            antiCheat = "Riot Vanguard (Ring-0 Driver)"
        }

        // 2. Engine & Renderer Heuristics
        if directory.contains("engine/binaries") || filename.contains("ue4") || filename.contains("ue5") {
            engine = "Unreal Engine"
            renderer = .d3dmetal
            sync = .esync
            metalFx = .temporal
        } else if directory.contains("unity") || directory.contains("_data") {
            engine = "Unity Engine"
            renderer = .dxvk
            sync = .fsync
        } else if filename.contains("witcher") || filename.contains("cyberpunk") {
            engine = "REDengine"
            renderer = .d3dmetal
            metalFx = .temporal
        } else if filename.contains("hl2.exe") || filename.contains("csgo.exe") || directory.contains("source") {
            engine = "Source Engine"
            renderer = .dxvk
            sync = .esync
        }

        let cleanTitle = ((path as NSString).lastPathComponent as NSString).deletingPathExtension

        return DetectedGameSignature(
            title: cleanTitle,
            is64Bit: is64Bit,
            primaryRenderer: renderer,
            detectedEngine: engine,
            antiCheatName: antiCheat,
            recommendedSync: sync,
            recommendedMetalFX: metalFx
        )
    }
}
