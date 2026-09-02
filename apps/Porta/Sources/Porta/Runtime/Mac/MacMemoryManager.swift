import Foundation
import Metal

public final class MacMemoryManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacMemoryManager()

    @Published public var totalMemoryBytes: UInt64 = 0
    @Published public var availableMemoryBytes: UInt64 = 0
    @Published public var usedMemoryBytes: UInt64 = 0
    @Published public var memoryPressureState: String = "Normal"
    @Published public var zeroCopySharedMemoryActive: Bool = true

    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var defaultMetalDevice: MTLDevice?

    public init() {
        self.totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
        self.defaultMetalDevice = MTLCreateSystemDefaultDevice()
        updateMemoryMetrics()
        startMemoryPressureMonitoring()
    }

    public func updateMemoryMetrics() {
        var pageSize: vm_size_t = 0
        let hostPort = mach_host_self()
        _ = host_page_size(hostPort, &pageSize)

        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let kerr = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let free = UInt64(vmStat.free_count) * UInt64(pageSize)
            let inactive = UInt64(vmStat.inactive_count) * UInt64(pageSize)
            let active = UInt64(vmStat.active_count) * UInt64(pageSize)
            let wired = UInt64(vmStat.wire_count) * UInt64(pageSize)
            let compressed = UInt64(vmStat.compressor_page_count) * UInt64(pageSize)

            let available = free + inactive
            let used = active + wired + compressed

            DispatchQueue.main.async {
                self.availableMemoryBytes = available
                self.usedMemoryBytes = used
            }
        }
    }

    public func startMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in
            let event = source.data
            if event.contains(.critical) {
                self?.memoryPressureState = "Critical"
                self?.trimMemoryCaches()
            } else if event.contains(.warning) {
                self?.memoryPressureState = "Warning"
                self?.trimMemoryCaches()
            } else {
                self?.memoryPressureState = "Normal"
            }
        }
        source.resume()
        self.memoryPressureSource = source
    }

    public func trimMemoryCaches() {
        // Purge non-essential Metal texture caches and disk staging buffers
        let cachePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Porta/Prefixes/default/metal_pso_cache")
        try? FileManager.default.removeItem(at: cachePath)
        try? FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
    }
}
