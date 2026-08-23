import Foundation
import Metal

public struct TileMemorylessTextureDescriptor: Sendable {
    public let pixelFormat: MTLPixelFormat
    public let width: Int
    public let height: Int
    public let isTransient: Bool
}

public final class TileMemoryCacheManager: ObservableObject, @unchecked Sendable {
    public static let shared = TileMemoryCacheManager()

    @Published public var totalMemorylessSavingsBytes: UInt64 = 0
    @Published public var activeMemorylessTexturesCount: Int = 0

    private let defaultDevice: MTLDevice?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
    }

    public func createTileMemorylessTexture(desc: TileMemorylessTextureDescriptor) -> MTLTexture? {
        guard let device = defaultDevice else { return nil }

        let mtlDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: desc.pixelFormat,
            width: desc.width,
            height: desc.height,
            mipmapped: false
        )

        // Apple Silicon TBDR Memoryless allocation (Stays entirely inside on-chip tile SRAM)
        mtlDesc.storageMode = .memoryless
        mtlDesc.usage = [.renderTarget]

        let texture = device.makeTexture(descriptor: mtlDesc)
        if texture != nil {
            // Calculate RAM bytes saved by not allocating in main physical memory
            let bytesPerPixel: UInt64 = 4
            let savedBytes = UInt64(desc.width * desc.height) * bytesPerPixel

            DispatchQueue.main.async {
                self.totalMemorylessSavingsBytes += savedBytes
                self.activeMemorylessTexturesCount += 1
            }
        }

        return texture
    }
}
