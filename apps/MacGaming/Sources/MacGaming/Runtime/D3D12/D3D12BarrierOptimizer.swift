import Foundation
import Metal

public enum D3D12ResourceState: UInt32, Sendable {
    case common = 0
    case vertexAndConstantBuffer = 0x1
    case index = 0x2
    case renderTarget = 0x4
    case unorderedAccess = 0x8
    case depthWrite = 0x10
    case depthRead = 0x20
    case pixelShaderResource = 0x40
    case nonPixelShaderResource = 0x80
}

public struct D3D12ResourceBarrier: Sendable {
    public let resourceId: UInt64
    public let stateBefore: D3D12ResourceState
    public let stateAfter: D3D12ResourceState

    public init(resourceId: UInt64, stateBefore: D3D12ResourceState, stateAfter: D3D12ResourceState) {
        self.resourceId = resourceId
        self.stateBefore = stateBefore
        self.stateAfter = stateAfter
    }
}

public final class D3D12BarrierOptimizer: ObservableObject, @unchecked Sendable {
    public static let shared = D3D12BarrierOptimizer()

    @Published public var totalBarriersEvaluated: UInt64 = 0
    @Published public var barriersEliminatedCount: UInt64 = 0
    @Published public var encoderSplitsAvoidedCount: UInt64 = 0

    private var trackedResourceStates: [UInt64: D3D12ResourceState] = [:]
    private let lock = NSLock()

    public init() {}

    public func optimizeBarriers(_ rawBarriers: [D3D12ResourceBarrier], inRenderPass: Bool) -> [D3D12ResourceBarrier] {
        lock.lock()
        defer { lock.unlock() }

        var optimalBarriers: [D3D12ResourceBarrier] = []

        for barrier in rawBarriers {
            totalBarriersEvaluated += 1

            let currentState = trackedResourceStates[barrier.resourceId] ?? barrier.stateBefore

            // Optimization 1: Redundant Barrier Elision (State is already identical)
            if currentState == barrier.stateAfter {
                barriersEliminatedCount += 1
                continue
            }

            // Optimization 2: TBDR Render Pass Read-After-Read Coalescing
            if inRenderPass && (currentState == .pixelShaderResource && barrier.stateAfter == .nonPixelShaderResource) {
                barriersEliminatedCount += 1
                encoderSplitsAvoidedCount += 1
                continue
            }

            // Update tracked state and retain required barrier
            trackedResourceStates[barrier.resourceId] = barrier.stateAfter
            optimalBarriers.append(barrier)
        }

        return optimalBarriers
    }

    public func resetTracking() {
        lock.lock()
        defer { lock.unlock() }
        trackedResourceStates.removeAll()
    }
}
