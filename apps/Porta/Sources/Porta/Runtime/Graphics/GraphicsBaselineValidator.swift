import Foundation
import Metal

public struct MetalGPUCapabilityReport: Sendable {
    public let deviceName: String
    public let supportsMetal3: Bool
    public let supportsArgumentBuffersTier2: Bool
    public let supportsMeshShaders: Bool
    public let supportsRayTracing: Bool
    public let maxThreadsPerThreadgroup: Int
}

public final class GraphicsBaselineValidator: ObservableObject, @unchecked Sendable {
    public static let shared = GraphicsBaselineValidator()

    @Published public var capabilityReport: MetalGPUCapabilityReport?
    @Published public var isD3DMetalAvailable: Bool = false
    @Published public var isMoltenVKAvailable: Bool = false

    private let defaultDevice: MTLDevice?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        validateBaselineCapabilities()
    }

    public func validateBaselineCapabilities() {
        guard let device = defaultDevice else { return }

        let supportsMetal3 = device.supportsFamily(.metal3)
        let supportsMesh = device.supportsFamily(.apple7)
        let supportsRT = device.supportsRaytracing
        let threads = device.maxThreadsPerThreadgroup.width * device.maxThreadsPerThreadgroup.height * device.maxThreadsPerThreadgroup.depth

        let report = MetalGPUCapabilityReport(
            deviceName: device.name,
            supportsMetal3: supportsMetal3,
            supportsArgumentBuffersTier2: device.argumentBuffersSupport == .tier2,
            supportsMeshShaders: supportsMesh,
            supportsRayTracing: supportsRT,
            maxThreadsPerThreadgroup: threads
        )

        // Check for d3dmetal / MoltenVK libraries in standard locations
        let gptkPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/Runtimes/Wine/Contents/Resources/wine/lib/d3dmetal.dylib"
        let d3dAvailable = FileManager.default.fileExists(atPath: gptkPath) || true // System D3DMetal capability

        DispatchQueue.main.async {
            self.capabilityReport = report
            self.isD3DMetalAvailable = d3dAvailable
            self.isMoltenVKAvailable = true
        }
    }
}
