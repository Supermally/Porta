import Foundation

public final class GraphicsOverrideManager: Sendable {
    public static let shared = GraphicsOverrideManager()

    public init() {}

    public func generateOverrides(for backend: GraphicsBackend, enableHud: Bool) -> [String: String] {
        var env: [String: String] = [:]
        var overrides: [String: String] = [
            "winemenubuilder.exe": "d",
            "mscms": "d"
        ]

        switch backend {
        case .d3dmetal:
            overrides["d3d12"] = "n,b"
            overrides["d3d11"] = "n,b"
            overrides["dxgi"] = "n,b"
            overrides["d3dcompiler_47"] = "n,b"
            overrides["d3dcompiler_43"] = "n,b"
            env["D3DMetal_LOG_LEVEL"] = "warn"
            env["WINE_D3D_METAL"] = "1"
            if enableHud {
                env["MTL_HUD_ENABLED"] = "1"
            }

        case .dxvk:
            overrides["d3d11"] = "n"
            overrides["d3d10core"] = "n"
            overrides["d3d9"] = "n"
            overrides["dxgi"] = "n"
            overrides["d3dcompiler_47"] = "n,b"
            env["DXVK_ASYNC"] = "1"
            env["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
            if enableHud {
                env["DXVK_HUD"] = "devinfo,fps,frametimes"
            }

        case .dxmt:
            overrides["d3d11"] = "n"
            overrides["dxgi"] = "n"

        case .moltenVK:
            overrides["winevulkan"] = "n,b"
            env["MVK_CONFIG_RESUME_ON_ACTIVATE"] = "1"
            env["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
            env["MVK_CONFIG_FULL_SCREEN_EXCLUSIVE_MODE"] = "1"

        case .nativeMetal:
            overrides["opengl32"] = "b"
            overrides["ddraw"] = "b"
        }

        let overrideString = overrides.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
        env["WINEDLLOVERRIDES"] = overrideString
        return env
    }
}
