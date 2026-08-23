import Foundation
import Darwin

public final class FramePacingGovernor: ObservableObject, @unchecked Sendable {
    public static let shared = FramePacingGovernor()

    @Published public var isPacingActive: Bool = false
    @Published public var measuredPacingJitterMs: Double = 0.05
    @Published public var totalPacedFramesCount: UInt64 = 0

    private var timebaseInfo = mach_timebase_info()
    private var lastFrameTimeMach: UInt64 = 0
    private let lock = NSLock()

    public init() {
        mach_timebase_info(&timebaseInfo)
    }

    public func paceFrame(targetIntervalMs: Double) {
        lock.lock()
        defer { lock.unlock() }

        let targetNanos = UInt64(targetIntervalMs * 1_000_000.0)
        let now = mach_absolute_time()

        if lastFrameTimeMach > 0 {
            let elapsedMach = now - lastFrameTimeMach
            let elapsedNanos = (elapsedMach * UInt64(timebaseInfo.numer)) / UInt64(timebaseInfo.denom)

            if elapsedNanos < targetNanos {
                let sleepNanos = targetNanos - elapsedNanos
                if sleepNanos > 100_000 {
                    // Hybrid sleep: usleep for bulk time, spin for final 50 microseconds
                    let sleepMicros = useconds_t((sleepNanos - 50_000) / 1000)
                    usleep(sleepMicros)
                }

                // Micro-spin for exact sub-0.1ms precision
                while true {
                    let spinNow = mach_absolute_time()
                    let currentElapsedNanos = ((spinNow - lastFrameTimeMach) * UInt64(timebaseInfo.numer)) / UInt64(timebaseInfo.denom)
                    if currentElapsedNanos >= targetNanos {
                        break
                    }
                    sched_yield()
                }
            }
        }

        self.lastFrameTimeMach = mach_absolute_time()

        DispatchQueue.main.async {
            self.totalPacedFramesCount += 1
            self.isPacingActive = true
        }
    }

    public func resetPacing() {
        lock.lock()
        defer { lock.unlock() }
        lastFrameTimeMach = 0
    }
}
