import Foundation
import Metal

public final class UnifiedSyncCoordinator: ObservableObject, @unchecked Sendable {
    public static let shared = UnifiedSyncCoordinator()

    @Published public var currentTimelineValue: UInt64 = 0
    @Published public var totalSyncEventsProcessed: UInt64 = 0

    private let defaultDevice: MTLDevice?
    private var sharedEvent: MTLSharedEvent?

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        if let device = defaultDevice {
            self.sharedEvent = device.makeSharedEvent()
        }
    }

    public func signalTimeline(to value: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = sharedEvent else { return }
        commandBuffer.encodeSignalEvent(event, value: value)

        DispatchQueue.main.async {
            self.currentTimelineValue = value
            self.totalSyncEventsProcessed += 1
        }
    }

    public func waitForTimeline(value: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = sharedEvent else { return }
        commandBuffer.encodeWaitForEvent(event, value: value)
    }

    public func waitUntilSignaledCPU(value: UInt64, timeoutMs: Double = 100.0) -> Bool {
        guard let event = sharedEvent else { return true }
        if event.signaledValue >= value { return true }

        let start = CFAbsoluteTimeGetCurrent()
        while event.signaledValue < value {
            if (CFAbsoluteTimeGetCurrent() - start) * 1000.0 > timeoutMs {
                return false
            }
            sched_yield()
        }
        return true
    }
}
