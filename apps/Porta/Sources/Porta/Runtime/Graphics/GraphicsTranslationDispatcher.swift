import Foundation

public enum WindowsGraphicsAPI: String, CaseIterable, Codable, Identifiable, Sendable {
    case directX9 = "DirectX 9"
    case directX10 = "DirectX 10"
    case directX11 = "DirectX 11"
    case directX12 = "DirectX 12"
    case vulkan = "Vulkan"
    case openGL = "OpenGL"
    case directDraw = "DirectDraw (Legacy 2D)"

    public var id: String { rawValue }
}

public struct DispatchRouteResult: Sendable {
    public let sourceAPI: WindowsGraphicsAPI
    public let targetBackend: GraphicsBackend
    public let routingReason: String
    public let fallbackBackend: GraphicsBackend?
}

public final class GraphicsTranslationDispatcher: ObservableObject, @unchecked Sendable {
    public static let shared = GraphicsTranslationDispatcher()

    @Published public var lastDispatchRoute: DispatchRouteResult?
    @Published public var totalDispatchesCount: Int = 0

    public init() {}

    public func dispatchGraphicsPipeline(
        api: WindowsGraphicsAPI,
        isModernDX11FeatureLevel: Bool = true,
        userOverride: GraphicsBackend? = nil
    ) -> DispatchRouteResult {
        if let override = userOverride {
            let result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: override,
                routingReason: "Explicit User Override Selected",
                fallbackBackend: nil
            )
            updateState(result)
            return result
        }

        let result: DispatchRouteResult
        switch api {
        case .directX9:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .dxvk,
                routingReason: "DirectX 9 ➔ DXVK (Vulkan/Metal Translation)",
                fallbackBackend: .nativeMetal
            )
        case .directX10:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .dxvk,
                routingReason: "DirectX 10 ➔ DXVK (Vulkan/Metal Translation)",
                fallbackBackend: .nativeMetal
            )
        case .directX11:
            if isModernDX11FeatureLevel {
                result = DispatchRouteResult(
                    sourceAPI: api,
                    targetBackend: .d3dmetal,
                    routingReason: "DirectX 11.3+ ➔ Apple D3DMetal (Direct Metal Pipeline)",
                    fallbackBackend: .dxvk
                )
            } else {
                result = DispatchRouteResult(
                    sourceAPI: api,
                    targetBackend: .dxvk,
                    routingReason: "DirectX 11.0 ➔ DXVK (Legacy Feature Levels)",
                    fallbackBackend: .d3dmetal
                )
            }
        case .directX12:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .d3dmetal,
                routingReason: "DirectX 12 ➔ Apple D3DMetal (Metal 3/4 Argument Buffers)",
                fallbackBackend: .moltenVK
            )
        case .vulkan:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .moltenVK,
                routingReason: "Vulkan 1.3 ➔ MoltenVK (Direct CAMetalLayer Swapchain)",
                fallbackBackend: nil
            )
        case .openGL:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .nativeMetal,
                routingReason: "OpenGL ➔ Wine Compatibility Driver Layer",
                fallbackBackend: nil
            )
        case .directDraw:
            result = DispatchRouteResult(
                sourceAPI: api,
                targetBackend: .nativeMetal,
                routingReason: "DirectDraw ➔ Wine Built-in 2D Surface Renderer",
                fallbackBackend: nil
            )
        }

        updateState(result)
        return result
    }

    private func updateState(_ result: DispatchRouteResult) {
        DispatchQueue.main.async {
            self.lastDispatchRoute = result
            self.totalDispatchesCount += 1
        }
    }
}
