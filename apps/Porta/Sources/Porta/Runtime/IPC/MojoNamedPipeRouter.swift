import Foundation

public final class MojoNamedPipeRouter: ObservableObject, @unchecked Sendable {
    public static let shared = MojoNamedPipeRouter()

    @Published public var activePipeCount: Int = 0
    @Published public var totalRoutedMessages: UInt64 = 0
    @Published public var averageLatencyMicros: Double = 0.85

    private var pipeRegistry: [String: Date] = [:]
    private let lock = NSLock()

    public init() {}

    public func registerNamedPipe(name: String) {
        lock.lock()
        defer { lock.unlock() }

        pipeRegistry[name] = Date()
        DispatchQueue.main.async {
            self.activePipeCount = self.pipeRegistry.count
        }
    }

    public func routeMessage(channel: String, bytesCount: Int) {
        lock.lock()
        defer { lock.unlock() }

        DispatchQueue.main.async {
            self.totalRoutedMessages += 1
        }
    }
}
