import Foundation

public final class GraphicsTranslationEngine: Sendable {
    public static let shared = GraphicsTranslationEngine()

    public init() {}

    public func buildEnvironment(for config: RuntimeEnvironmentConfig, prefixURL: URL, cacheURL: URL) -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        // 1. Wine Prefix & Architecture
        env["WINEPREFIX"] = prefixURL.path
        env["WINEARCH"] = "win64"
        env["WINEDEBUG"] = "-all,fixme-all"

        // 2. Synchronization Primitives
        switch config.syncBackend {
        case .esync:
            env["WINEESYNC"] = "1"
            env["WINEFSYNC"] = "0"
        case .fsync:
            env["WINEESYNC"] = "0"
            env["WINEFSYNC"] = "1"
        case .standard:
            env["WINEESYNC"] = "0"
            env["WINEFSYNC"] = "0"
        }

        // 3. Apple Metal HUD Telemetry
        if config.enableMetalHud {
            env["MTL_HUD_ENABLED"] = "1"
            env["DXVK_HUD"] = "fps,frametimes,drawcalls"
        } else {
            env["MTL_HUD_ENABLED"] = "0"
            env["DXVK_HUD"] = "0"
        }

        // 4. Metal Pipeline State Object (PSO) Pre-Caching on Disk
        if config.enableShaderDiskCache {
            env["MTL_SHADER_CACHE_PATH"] = cacheURL.path
            env["DXVK_STATE_CACHE_PATH"] = cacheURL.path
        }

        // 5. Graphics Backend Overrides (D3DMetal vs DXVK vs MoltenVK)
        var dllOverrides = ["winemenubuilder.exe": "d", "mscms": "d"]
        env["D3DMetal_FEATURE_LEVEL"] = "11_1"
        env["WINE_D3D11_FEATURE_LEVEL"] = "11_1"
        env["DXVK_FEATURE_LEVEL"] = "11_1"
        env["DXVK_CONFIG"] = "dxgi.maxFeatureLevel = 11_1; d3d11.maxFeatureLevel = 11_1; dxgi.customVendorId = 0x10de; dxgi.customDeviceId = 0x1e84; d3d11.shaderModel = 5"
        env["DXVK_FILTER_DEVICE_NAME"] = "Apple M"
        env["DXVK_ENABLE_NVAPI"] = "1"

        switch config.graphicsBackend {
        case .d3dmetal:
            dllOverrides["d3d12"] = "n,b"
            dllOverrides["d3d11"] = "n,b"
            dllOverrides["dxgi"] = "n,b"
            dllOverrides["d3dcompiler_47"] = "n,b"
            dllOverrides["d3dcompiler_43"] = "n,b"
            env["D3DMetal_LOG_LEVEL"] = "warn"
            env["WINE_D3D_METAL"] = "1"
        case .dxvk:
            dllOverrides["d3d11"] = "n"
            dllOverrides["d3d10core"] = "n"
            dllOverrides["d3d9"] = "n"
            dllOverrides["dxgi"] = "n"
            dllOverrides["d3dcompiler_47"] = "n,b"
            dllOverrides["d3dcompiler_43"] = "n,b"
        case .dxmt:
            dllOverrides["d3d11"] = "n"
            dllOverrides["dxgi"] = "n"
            dllOverrides["d3dcompiler_47"] = "n,b"
        case .moltenVK, .nativeMetal:
            break
        }

        for (k, v) in config.customDllOverrides {
            dllOverrides[k] = v
        }

        let overrideString = dllOverrides.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
        env["WINEDLLOVERRIDES"] = overrideString

        // 6. MetalFX Upscaling Flags
        switch config.metalFXMode {
        case .off:
            env["METALFX_ENABLE"] = "0"
        case .spatial:
            env["METALFX_ENABLE"] = "1"
            env["METALFX_MODE"] = "spatial"
        case .temporal:
            env["METALFX_ENABLE"] = "1"
            env["METALFX_MODE"] = "temporal"
        }

        return env
    }
}
