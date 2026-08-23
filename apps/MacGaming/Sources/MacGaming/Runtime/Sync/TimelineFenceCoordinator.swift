import Foundation
import Metal

public final class TimelineFenceCoordinator: ObservableObject, @unchecked Sendable {
    public static let shared = TimelineFenceCoordinator()

    @Published public var currentSignaledTimeline: UInt64 = 0
    @Published public var activeListenersCount: Int = 0
    @Published public var timelineSignalsDispatched: UInt64 = 0

    private let defaultDevice: MTLDevice?
    private var sharedEvent: MTLSharedEvent?
    private let lock = NSLock()

    public init() {
        self.defaultDevice = MTLCreateSystemDefaultDevice()
        if let device = defaultDevice {
            self.sharedEvent = device.makeSharedEvent()
        }
    }

    public func signalTimeline(value: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = sharedEvent else { return }
        commandBuffer.encodeSignalEvent(event, value: value)

        DispatchQueue.main.async {
            self.currentSignaledTimeline = value
            self.timelineSignalsDispatched += 1
        }
    }

    public func waitTimeline(value: UInt64, on commandBuffer: MTLCommandBuffer) {
        guard let event = sharedEvent else { return }
        commandBuffer.encodeWaitForEvent(event, value: value)
    }

    public func registerCompletionListener(atValue value: UInt64, completion: @escaping @Sendable () -> Void) {
        guard let event = sharedEvent else {
            completion()
            return
        }

        if event.signaledValue >= value {
            completion()
            return
        }

        DispatchQueue.main.async {
            self.activeListenersCount += 1
        }

        let listener = MTLSharedEventListener()
        event.notify(listener, atValue: value) { _, _ in
            completion()
            DispatchQueue.main.async {
                self.activeListenersCount = max(0, self.activeListenersCount - 1)
            }
        }
    }
}
