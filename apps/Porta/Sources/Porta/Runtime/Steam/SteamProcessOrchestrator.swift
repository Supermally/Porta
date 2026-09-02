///
/// SteamProcessOrchestrator manages the lifecycle, sandboxing, and execution of Steam within the Forge runtime.
///
import Foundation

public final class SteamProcessOrchestrator: ObservableObject, @unchecked Sendable {
    public static let shared = SteamProcessOrchestrator()

    @Published public var isSteamRunning: Bool = false
    @Published public var isWebHelperActive: Bool = false
    @Published public var activeCEFProcessCount: Int = 0

    public init() {}

    public func computeSteamLaunchArguments(baseArgs: [String] = []) -> [String] {
        var args = baseArgs
        let requiredFlags = [
            "-no-cef-sandbox",
            "-allosarches",
            "-cef-disable-gpu-compositing"
        ]

        for flag in requiredFlags {
            if !args.contains(flag) {
                args.append(flag)
            }
        }
        return args
    }

    public func computeWebHelperLaunchArguments(baseArgs: [String] = []) -> [String] {
        var args = baseArgs
        let cefFlags = [
            "--no-sandbox",
            "--in-process-gpu",
            "--disable-gpu-sandbox",
            "--disable-direct-composition",
            "--allosarches"
        ]

        for flag in cefFlags {
            if !args.contains(flag) {
                args.append(flag)
            }
        }
        return args
    }
}
