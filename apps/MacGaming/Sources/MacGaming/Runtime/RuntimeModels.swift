import Foundation

// MARK: - Graphics Translation Backends
public enum GraphicsBackend: String, CaseIterable, Codable, Identifiable, Sendable {
    case d3dmetal = "Apple D3DMetal (DirectX 12 / Metal 3)"
    case dxvk = "DXVK 2.3+ (DirectX 9/10/11 / Vulkan)"
    case dxmt = "DXMT (DirectX 11 / Metal Native)"
    case moltenVK = "MoltenVK (Vulkan 1.3 on Metal)"
    case nativeMetal = "Native Metal (macOS Binary)"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .d3dmetal: return "D3DMetal"
        case .dxvk: return "DXVK"
        case .dxmt: return "DXMT"
        case .moltenVK: return "MoltenVK"
        case .nativeMetal: return "Native Metal"
        }
    }
}

// MARK: - MetalFX Upscaling Modes
public enum MetalFXMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case off = "Disabled"
    case spatial = "MetalFX Spatial (Ultra-Fast)"
    case temporal = "MetalFX Temporal (High Fidelity)"

    public var id: String { rawValue }
}

// MARK: - Synchronization Primitive
public enum SyncBackend: String, CaseIterable, Codable, Identifiable, Sendable {
    case esync = "Eventfd Synchronization (Esync)"
    case fsync = "Futex Synchronization (Fsync)"
    case standard = "Standard Wine Server Pipes"

    public var id: String { rawValue }
}

// MARK: - HDR & EDR Presentation Mode
public enum HDRPresentationMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic = "Automatic (Match Display)"
    case edr10Bit = "EDR 10-Bit (HDR10)"
    case edr16BitFloat = "EDR 16-Bit Float (Peak XDR)"
    case sRGB = "Standard Dynamic Range (sRGB)"

    public var id: String { rawValue }
}

// MARK: - Runtime Environment Configuration
public struct RuntimeEnvironmentConfig: Codable, Sendable {
    public var graphicsBackend: GraphicsBackend
    public var metalFXMode: MetalFXMode
    public var syncBackend: SyncBackend
    public var enableMetalHud: Bool
    public var enableShaderDiskCache: Bool
    public var targetFps: Int
    public var hdrMode: HDRPresentationMode
    public var customDllOverrides: [String: String]

    public init(
        graphicsBackend: GraphicsBackend = .d3dmetal,
        metalFXMode: MetalFXMode = .off,
        syncBackend: SyncBackend = .esync,
        enableMetalHud: Bool = false,
        enableShaderDiskCache: Bool = true,
        targetFps: Int = 120,
        hdrMode: HDRPresentationMode = .automatic,
        customDllOverrides: [String: String] = [:]
    ) {
        self.graphicsBackend = graphicsBackend
        self.metalFXMode = metalFXMode
        self.syncBackend = syncBackend
        self.enableMetalHud = enableMetalHud
        self.enableShaderDiskCache = enableShaderDiskCache
        self.targetFps = targetFps
        self.hdrMode = hdrMode
        self.customDllOverrides = customDllOverrides
    }
}
