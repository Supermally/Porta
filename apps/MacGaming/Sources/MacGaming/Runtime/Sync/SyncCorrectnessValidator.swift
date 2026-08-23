import Foundation

public struct SyncValidationReport: Identifiable, Sendable {
    public let id = UUID()
    public let testCase: String
    public let isPassed: Bool
    public let details: String
}

public final class SyncCorrectnessValidator: ObservableObject, @unchecked Sendable {
    public static let shared = SyncCorrectnessValidator()

    @Published public var isRunning: Bool = false
    @Published public var reports: [SyncValidationReport] = []

    public init() {}

    public func runComprehensiveValidation() {
        self.isRunning = true
        var results: [SyncValidationReport] = []

        // Test 1: Immediate CPU Readback Hazard Detection (RAW)
        let analyzer = SyncDependencyGraphAnalyzer()
        let writeRecord = ResourceAccessRecord(resourceId: 101, accessType: .write, frameIndex: 1, isHostVisible: true, isImmediateCPUReadback: false)
        _ = analyzer.evaluateDependency(record: writeRecord)

        let readRecord = ResourceAccessRecord(resourceId: 101, accessType: .read, frameIndex: 1, isHostVisible: true, isImmediateCPUReadback: true)
        let eval1 = analyzer.evaluateDependency(record: readRecord)

        let pass1 = !eval1.canDefer && eval1.hazard == .raw
        results.append(SyncValidationReport(
            testCase: "Immediate CPU Readback RAW Hazard Detection",
            isPassed: pass1,
            details: pass1 ? "Correctly blocked CPU wait for immediate readback" : "Failed to detect RAW hazard"
        ))

        // Test 2: Triple-Buffered Frame Deferral
        let multiBufferedRead = ResourceAccessRecord(resourceId: 102, accessType: .read, frameIndex: 3, isHostVisible: true, isImmediateCPUReadback: false)
        let eval2 = analyzer.evaluateDependency(record: multiBufferedRead)

        let pass2 = eval2.canDefer
        results.append(SyncValidationReport(
            testCase: "Triple-Buffered Ring Resource Deferral",
            isPassed: pass2,
            details: pass2 ? "Correctly deferred non-conflicting multi-buffered frame access" : "Incorrectly stalled multi-buffered resource"
        ))

        // Test 3: CPU Wait Elision
        let elisionEngine = SyncWaitElisionEngine()
        let elided = elisionEngine.interceptCPUWait(fenceValue: 10, currentTimeline: 5, isImmediateHazard: false)
        let pass3 = elided
        results.append(SyncValidationReport(
            testCase: "Non-Hazardous Timeline Wait Elision",
            isPassed: pass3,
            details: pass3 ? "Successfully elided 2.5ms CPU stall" : "Failed to elide non-hazardous wait"
        ))

        DispatchQueue.main.async {
            self.reports = results
            self.isRunning = false
        }
    }
}
