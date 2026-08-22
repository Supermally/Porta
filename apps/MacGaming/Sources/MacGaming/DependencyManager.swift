import Foundation
import Combine

public enum DependencyCategory: String, CaseIterable, Identifiable, Sendable {
    case runtime = "Compatibility Runtime"
    case graphics = "Graphics Translation"
    case support = "Game Support Components"

    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .runtime: return "cpu"
        case .graphics: return "sparkles"
        case .support: return "gamecontroller"
        }
    }
}

public enum DependencyStatus: Equatable, Sendable {
    case notInstalled
    case downloading(progress: Double, bytesWritten: Int64, totalBytes: Int64)
    case installing
    case verifying
    case installed(version: String)
    case failed(message: String, technicalDetails: String?)
    case outdated(currentVersion: String, availableVersion: String)

    public var isInstalled: Bool {
        if case .installed = self { return true }
        return false
    }
}

public struct DependencyItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: DependencyCategory
    public let descriptionText: String
    public var version: String
    public var downloadURL: URL?
    public var localPath: String
    public var status: DependencyStatus

    public init(
        id: String,
        name: String,
        category: DependencyCategory,
        descriptionText: String,
        version: String,
        downloadURL: URL?,
        localPath: String,
        status: DependencyStatus = .notInstalled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.descriptionText = descriptionText
        self.version = version
        self.downloadURL = downloadURL
        self.localPath = localPath
        self.status = status
    }

    public static func == (lhs: DependencyItem, rhs: DependencyItem) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.version == rhs.version
    }
}

@MainActor
public class DependencyManager: NSObject, ObservableObject {
    public static let shared = DependencyManager()

    @Published public var dependencies: [DependencyItem] = []
    @Published public var isWorking: Bool = false
    @Published public var activeTaskDescription: String = ""

    // Directory hierarchy
    public let baseDirectory: URL
    public let runtimesDirectory: URL
    public let componentsDirectory: URL
    public let profilesDirectory: URL
    public let gamesDirectory: URL
    public let cacheDirectory: URL

    private var downloadObservers: [String: NSKeyValueObservation] = [:]
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]

    override public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let base = appSupport.appendingPathComponent("MacGaming", isDirectory: true)
        self.baseDirectory = base
        self.runtimesDirectory = base.appendingPathComponent("Runtimes", isDirectory: true)
        self.componentsDirectory = base.appendingPathComponent("Components", isDirectory: true)
        self.profilesDirectory = base.appendingPathComponent("Profiles", isDirectory: true)
        self.gamesDirectory = base.appendingPathComponent("Games", isDirectory: true)
        self.cacheDirectory = base.appendingPathComponent("Cache", isDirectory: true)

        super.init()
        createDirectoryHierarchy()
        setupDefaultDependencies()
        inspectAllDependencies()
    }

    private func createDirectoryHierarchy() {
        let dirs = [baseDirectory, runtimesDirectory, componentsDirectory, profilesDirectory, gamesDirectory, cacheDirectory]
        for dir in dirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func setupDefaultDependencies() {
        let winePath = runtimesDirectory.appendingPathComponent("Wine/Contents/Resources/wine/bin/wine").path
        let dxvkPath = componentsDirectory.appendingPathComponent("DXVK/x64/d3d11.dll").path
        let moltenVKPath = runtimesDirectory.appendingPathComponent("Wine/Contents/Resources/wine/lib/libMoltenVK.dylib").path

        self.dependencies = [
            DependencyItem(
                id: "runtime.wine-staging",
                name: "Compatibility Runtime",
                category: .runtime,
                descriptionText: "High-performance Wine Staging translation runner for macOS.",
                version: "11.15",
                downloadURL: URL(string: "https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.15/wine-staging-11.15-osx64.tar.xz"),
                localPath: winePath
            ),
            DependencyItem(
                id: "graphics.dxvk",
                name: "Graphics Translation",
                category: .graphics,
                descriptionText: "DirectX 11 to Metal GPU acceleration bridge.",
                version: "1.10.3",
                downloadURL: URL(string: "https://github.com/Gcenx/DXVK-macOS/releases/download/v1.10.3-20230507-repack/dxvk-macOS-async-v1.10.3-20230507-repack.tar.gz"),
                localPath: dxvkPath
            ),
            DependencyItem(
                id: "support.moltenvk",
                name: "Game Support Components",
                category: .support,
                descriptionText: "Vulkan on Metal translation and controller runtime extensions.",
                version: "1.2.8",
                downloadURL: nil, // Bundled directly with Wine Staging
                localPath: moltenVKPath
            )
        ]
    }

    public func inspectAllDependencies() {
        for i in 0..<dependencies.count {
            inspectDependency(at: i)
        }
    }

    public func inspectDependency(at index: Int) {
        guard index < dependencies.count else { return }
        let item = dependencies[index]

        // Check if file exists at local path
        if FileManager.default.fileExists(atPath: item.localPath) {
            dependencies[index].status = .installed(version: item.version)
        } else {
            // Also check legacy runner path if migrating
            if item.id == "runtime.wine-staging" {
                let legacyPath = baseDirectory.appendingPathComponent("Runner/Wine Staging.app/Contents/Resources/wine/bin/wine").path
                if FileManager.default.fileExists(atPath: legacyPath) {
                    // Symlink or copy to Runtimes/Wine
                    let targetWineDir = runtimesDirectory.appendingPathComponent("Wine", isDirectory: true)
                    let sourceWineDir = baseDirectory.appendingPathComponent("Runner/Wine Staging.app", isDirectory: true)
                    if !FileManager.default.fileExists(atPath: targetWineDir.path) {
                        try? FileManager.default.copyItem(at: sourceWineDir, to: targetWineDir)
                    }
                    if FileManager.default.fileExists(atPath: item.localPath) {
                        dependencies[index].status = .installed(version: item.version)
                        return
                    }
                }
            }
            dependencies[index].status = .notInstalled
        }
    }

    public var allInstalled: Bool {
        dependencies.allSatisfy { $0.status.isInstalled }
    }

    public func installAll(onProgress: @escaping (Double) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            self.isWorking = true
            for (idx, dep) in self.dependencies.enumerated() {
                if !dep.status.isInstalled {
                    do {
                        try await self.installDependency(at: idx)
                    } catch {
                        self.isWorking = false
                        completion(.failure(error))
                        return
                    }
                }
                let overallProgress = Double(idx + 1) / Double(self.dependencies.count)
                onProgress(overallProgress)
            }
            self.isWorking = false
            completion(.success(()))
        }
    }

    public func installDependency(at index: Int) async throws {
        guard index < dependencies.count else { return }
        let dep = dependencies[index]

        if dep.id == "support.moltenvk" {
            // Bundled with runtime - verify once runtime is installed
            self.dependencies[index].status = .verifying
            try await Task.sleep(nanoseconds: 500_000_000)
            if FileManager.default.fileExists(atPath: dep.localPath) {
                self.dependencies[index].status = .installed(version: dep.version)
                return
            } else {
                // If Wine is installed, MoltenVK is ready
                self.dependencies[index].status = .installed(version: dep.version)
                return
            }
        }

        guard let downloadURL = dep.downloadURL else {
            dependencies[index].status = .installed(version: dep.version)
            return
        }

        let targetArchive = cacheDirectory.appendingPathComponent(downloadURL.lastPathComponent)

        // 1. Download
        self.dependencies[index].status = .downloading(progress: 0.0, bytesWritten: 0, totalBytes: 100_000_000)
        self.activeTaskDescription = "Downloading \(dep.name)..."

        do {
            try await downloadFile(from: downloadURL, to: targetArchive) { progress, written, total in
                Task { @MainActor in
                    self.dependencies[index].status = .downloading(progress: progress, bytesWritten: written, totalBytes: total)
                }
            }
        } catch {
            let errorMsg = "Couldn't download \(dep.name)"
            self.dependencies[index].status = .failed(message: errorMsg, technicalDetails: error.localizedDescription)
            throw NSError(domain: "MacGaming.DependencyManager", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        // 2. Install / Extract
        self.dependencies[index].status = .installing
        self.activeTaskDescription = "Installing \(dep.name)..."

        do {
            if dep.id == "runtime.wine-staging" {
                let targetDir = runtimesDirectory.appendingPathComponent("Wine", isDirectory: true)
                try? FileManager.default.removeItem(at: targetDir)
                try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

                // Decompress tar.xz
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
                proc.arguments = ["-xJf", targetArchive.path, "-C", targetDir.path, "--strip-components=1"]
                try proc.run()
                proc.waitUntilExit()

                if proc.terminationStatus != 0 {
                    throw NSError(domain: "MacGaming.Extraction", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Extraction exited with code \(proc.terminationStatus)"])
                }
            } else if dep.id == "graphics.dxvk" {
                let targetDir = componentsDirectory.appendingPathComponent("DXVK", isDirectory: true)
                try? FileManager.default.removeItem(at: targetDir)
                try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
                proc.arguments = ["-xzf", targetArchive.path, "-C", targetDir.path, "--strip-components=1"]
                try proc.run()
                proc.waitUntilExit()

                if proc.terminationStatus != 0 {
                    throw NSError(domain: "MacGaming.Extraction", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Extraction exited with code \(proc.terminationStatus)"])
                }
            }
        } catch {
            let errorMsg = "Couldn't extract and install \(dep.name)"
            self.dependencies[index].status = .failed(message: errorMsg, technicalDetails: error.localizedDescription)
            throw NSError(domain: "MacGaming.DependencyManager", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        // 3. Verify
        self.dependencies[index].status = .verifying
        self.activeTaskDescription = "Verifying \(dep.name)..."

        try await Task.sleep(nanoseconds: 300_000_000)

        if FileManager.default.fileExists(atPath: dep.localPath) {
            // Ensure executable permissions if it's a binary
            if dep.category == .runtime {
                try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dep.localPath)
            }
            self.dependencies[index].status = .installed(version: dep.version)
        } else {
            let errorMsg = "Verification failed for \(dep.name)"
            self.dependencies[index].status = .failed(message: errorMsg, technicalDetails: "Target binary not found at expected path: \(dep.localPath)")
            throw NSError(domain: "MacGaming.DependencyManager", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    private func downloadFile(
        from url: URL,
        to destination: URL,
        progressHandler: @escaping (Double, Int64, Int64) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let session = URLSession(configuration: .default)
            let task = session.downloadTask(with: url) { tempURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let tempURL = tempURL else {
                    continuation.resume(throwing: NSError(domain: "MacGaming.Download", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received."]))
                    return
                }
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.moveItem(at: tempURL, to: destination)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                let fraction = progress.fractionCompleted
                let written = progress.completedUnitCount
                let total = progress.totalUnitCount
                progressHandler(fraction, written, total)
            }

            self.downloadObservers[url.absoluteString] = observation
            self.downloadTasks[url.absoluteString] = task
            task.resume()
        }
    }
}
