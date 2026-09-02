import Foundation
import Metal
import MetalFX

public final class MetalFXRuntimeScaler: ObservableObject, @unchecked Sendable {
    public static let shared = MetalFXRuntimeScaler()

    @Published public var activePreset: MetalFXQualityPreset = .off
    @Published public var isHardwareAccelerated: Bool = true
    @Published public var totalUpscaledFramesCount: UInt64 = 0

    private let defaultDevice: MTLDevice?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
    }

    public func createSpatialScaler(
        inputWidth: Int,
        inputHeight: Int,
        outputWidth: Int,
        outputHeight: Int,
        colorFormat: MTLPixelFormat
    ) -> MTLFXSpatialScaler? {
        guard let device = defaultDevice else { return nil }

        let desc = MTLFXSpatialScalerDescriptor()
        desc.inputWidth = inputWidth
        desc.inputHeight = inputHeight
        desc.outputWidth = outputWidth
        desc.outputHeight = outputHeight
        desc.colorTextureFormat = colorFormat
        desc.outputTextureFormat = colorFormat
        desc.colorProcessingMode = .perceptual

        return desc.makeSpatialScaler(device: device)
    }

    public func createTemporalScaler(
        inputWidth: Int,
        inputHeight: Int,
        outputWidth: Int,
        outputHeight: Int,
        colorFormat: MTLPixelFormat,
        depthFormat: MTLPixelFormat,
        motionFormat: MTLPixelFormat
    ) -> MTLFXTemporalScaler? {
        guard let device = defaultDevice else { return nil }

        let desc = MTLFXTemporalScalerDescriptor()
        desc.inputWidth = inputWidth
        desc.inputHeight = inputHeight
        desc.outputWidth = outputWidth
        desc.outputHeight = outputHeight
        desc.colorTextureFormat = colorFormat
        desc.depthTextureFormat = depthFormat
        desc.motionTextureFormat = motionFormat
        desc.outputTextureFormat = colorFormat

        return desc.makeTemporalScaler(device: device)
    }
}
