import Foundation
import GameController

public struct ConnectedControllerInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let isWireless: Bool
    public let hasHaptics: Bool
    public let batteryLevel: Float?
    public let vendorName: String
}

public final class MacInputManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacInputManager()

    @Published public var connectedControllers: [ConnectedControllerInfo] = []
    @Published public var lowLatencyBluetoothActive: Bool = false

    public init() {
        startControllerObservation()
        refreshControllers()
    }

    public func startControllerObservation() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshControllers()
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshControllers()
        }
    }

    public func refreshControllers() {
        let controllers = GCController.controllers()
        var list: [ConnectedControllerInfo] = []

        for (index, controller) in controllers.enumerated() {
            let name = controller.vendorName ?? "Gamepad \(index + 1)"
            let isWireless = !controller.isAttachedToDevice
            let hasHaptics = controller.haptics != nil
            let battery = controller.battery?.batteryLevel

            list.append(ConnectedControllerInfo(
                id: "\(controller.hashValue)",
                name: name,
                isWireless: isWireless,
                hasHaptics: hasHaptics,
                batteryLevel: battery,
                vendorName: controller.vendorName ?? "Standard Controller"
            ))
        }

        DispatchQueue.main.async {
            self.connectedControllers = list
        }
    }

    public func configureLowLatencyInput(enabled: Bool) {
        DispatchQueue.main.async {
            self.lowLatencyBluetoothActive = enabled
        }
    }
}
