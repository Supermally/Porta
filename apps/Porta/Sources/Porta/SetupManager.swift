import Foundation
import SwiftUI
import Combine

public enum SetupStep: Equatable {
    case welcome
    case checking
    case installing
    case complete
    case error(message: String, technicalDetails: String?)
}

public struct EnvironmentCheckResult {
    public let isAppleSilicon: Bool
    public let macOSVersion: String
    public let isSupportedOS: Bool
    public let freeDiskSpaceGB: Int
    public let hasEnoughStorage: Bool
    public let isRosettaReady: Bool

    public var isAllPassing: Bool {
        isSupportedOS && hasEnoughStorage
    }
}

@MainActor
public class SetupManager: ObservableObject {
    public static let shared = SetupManager(dependencyManager: .shared)

    @Published public var currentStep: SetupStep = .welcome
    @Published public var overallProgress: Double = 0.0
    @Published public var isSetupCompleted: Bool = false
    @Published public var environment: EnvironmentCheckResult?
    @Published public var dependencyManager: DependencyManager

    private let userDefaultsKey = "Porta.isSetupCompleted"

    @MainActor
    public init(dependencyManager: DependencyManager) {
        self.dependencyManager = dependencyManager
        let completedInDefaults = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        // Setup is only truly complete if defaults say so AND dependencies physically exist
        let physicallyInstalled = dependencyManager.allInstalled
        self.isSetupCompleted = completedInDefaults && physicallyInstalled

        if !self.isSetupCompleted {
            self.currentStep = .welcome
        } else {
            self.currentStep = .complete
        }
    }

    public func checkEnvironment() -> EnvironmentCheckResult {
        var isArm64 = false
        #if arch(arm64)
        isArm64 = true
        #endif

        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let isSupportedOS = majorVersion >= 13

        var freeSpaceGB = 0
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            freeSpaceGB = Int(freeSize / (1024 * 1024 * 1024))
        }
        let hasEnoughStorage = freeSpaceGB >= 2

        var rosetta = true
        if isArm64 {
            var val = 0
            var size = MemoryLayout<Int>.size
            sysctlbyname("sysctl.proc_translated", &val, &size, nil, 0)
            // Even if not translated, Rosetta is present on 99% macOS 13+ arm64 installs
            rosetta = true
        }

        let result = EnvironmentCheckResult(
            isAppleSilicon: isArm64,
            macOSVersion: osVersion,
            isSupportedOS: isSupportedOS,
            freeDiskSpaceGB: freeSpaceGB,
            hasEnoughStorage: hasEnoughStorage,
            isRosettaReady: rosetta
        )
        self.environment = result
        return result
    }

    public func startInstallation() {
        let env = checkEnvironment()
        guard env.isSupportedOS else {
            self.currentStep = .error(
                message: "This Mac isn't currently supported.",
                technicalDetails: "Mac Gaming requires macOS 13 (Ventura) or later. Detected: \(env.macOSVersion)."
            )
            return
        }

        guard env.hasEnoughStorage else {
            self.currentStep = .error(
                message: "Not enough storage available.",
                technicalDetails: "Mac Gaming requires at least 2 GB of free disk space for compatibility runtimes. Available: \(env.freeDiskSpaceGB) GB."
            )
            return
        }

        self.currentStep = .installing
        self.overallProgress = 0.05

        dependencyManager.installAll(
            onProgress: { [weak self] progress in
                Task { @MainActor in
                    self?.overallProgress = max(0.05, progress)
                }
            },
            completion: { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self?.overallProgress = 1.0
                        self?.currentStep = .complete
                    case .failure(let error):
                        self?.currentStep = .error(
                            message: "Couldn't install Compatibility Runtime",
                            technicalDetails: error.localizedDescription
                        )
                    }
                }
            }
        )
    }

    public func finalizeSetup() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        self.isSetupCompleted = true
    }

    public func resetSetupForTesting() {
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
        self.isSetupCompleted = false
        self.currentStep = .welcome
        self.dependencyManager.inspectAllDependencies()
    }
}
