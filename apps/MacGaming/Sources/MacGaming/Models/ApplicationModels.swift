import Foundation
import SwiftUI

// MARK: - Application Categories
public enum ApplicationCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All"
    case recent = "Recent"
    case favorites = "Favorites"
    case games = "Games"
    case utilities = "Utilities"
    case creative = "Creative"
    case development = "Development"
    case launchers = "Launchers"
    case other = "Other"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .recent: return "clock.fill"
        case .favorites: return "star.fill"
        case .games: return "gamecontroller.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .creative: return "paintpalette.fill"
        case .development: return "curlybraces"
        case .launchers: return "arrow.up.forward.app.fill"
        case .other: return "folder.fill"
        }
    }
}

// MARK: - Launcher Providers
public enum LauncherProvider: Hashable, Codable, Sendable {
    case standalone
    case steam(appId: String)
    case epic(appName: String)
    case gog(gameId: String)
    case ubisoft
    case ea
    case custom(name: String)

    public var displayName: String {
        switch self {
        case .standalone: return "Standalone"
        case .steam(let appId): return "Steam (\(appId))"
        case .epic(let appName): return "Epic Games (\(appName))"
        case .gog(let gameId): return "GOG Galaxy (\(gameId))"
        case .ubisoft: return "Ubisoft Connect"
        case .ea: return "EA App"
        case .custom(let name): return name
        }
    }

    public var providerIcon: String {
        switch self {
        case .standalone: return "app.fill"
        case .steam: return "gamecontroller.fill"
        case .epic: return "bolt.circle.fill"
        case .gog: return "globe.americas.fill"
        case .ubisoft: return "circle.grid.cross.fill"
        case .ea: return "play.circle.fill"
        case .custom: return "cube.fill"
        }
    }
}

// MARK: - Universal Application Model
public struct AppItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var name: String
    public var category: ApplicationCategory
    public var publisher: String
    public var version: String
    public var architecture: String // "x64", "x86", "arm64"
    public var iconUrl: String?
    public var localIconPath: String?
    public var headerImageUrl: String?
    
    // Execution Configuration
    public var executablePath: String
    public var arguments: String
    public var workingDirectory: String
    public var environmentId: String // Links to EnvironmentItem
    public var runtimeId: String     // Links to RuntimeItem
    public var launcherProvider: LauncherProvider
    
    // Graphics & Compatibility
    public var compatibilityTier: CompatibilityBadge
    public var graphicsApi: String // "DirectX 12", "DirectX 11", "DirectX 9", "Vulkan", "OpenGL"
    public var useD3DMetal: Bool
    public var enableHud: Bool
    public var enableEsync: Bool
    public var enableFsync: Bool
    
    // Metadata & State
    public var lastUsed: Date?
    public var isFavorite: Bool
    public var sizeOnDisk: Int64
    public var installDate: Date
    public var tags: [String]

    public init(
        id: String,
        name: String,
        category: ApplicationCategory = .other,
        publisher: String = "Unknown",
        version: String = "1.0.0",
        architecture: String = "x64",
        iconUrl: String? = nil,
        localIconPath: String? = nil,
        headerImageUrl: String? = nil,
        executablePath: String,
        arguments: String = "",
        workingDirectory: String = "",
        environmentId: String = "default",
        runtimeId: String = "forge_wine10",
        launcherProvider: LauncherProvider = .standalone,
        compatibilityTier: CompatibilityBadge = .compatible,
        graphicsApi: String = "DirectX 11",
        useD3DMetal: Bool = true,
        enableHud: Bool = false,
        enableEsync: Bool = true,
        enableFsync: Bool = true,
        lastUsed: Date? = nil,
        isFavorite: Bool = false,
        sizeOnDisk: Int64 = 0,
        installDate: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.publisher = publisher
        self.version = version
        self.architecture = architecture
        self.iconUrl = iconUrl
        self.localIconPath = localIconPath
        self.headerImageUrl = headerImageUrl
        self.executablePath = executablePath
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environmentId = environmentId
        self.runtimeId = runtimeId
        self.launcherProvider = launcherProvider
        self.compatibilityTier = compatibilityTier
        self.graphicsApi = graphicsApi
        self.useD3DMetal = useD3DMetal
        self.enableHud = enableHud
        self.enableEsync = enableEsync
        self.enableFsync = enableFsync
        self.lastUsed = lastUsed
        self.isFavorite = isFavorite
        self.sizeOnDisk = sizeOnDisk
        self.installDate = installDate
        self.tags = tags
    }

    public var formattedSize: String {
        guard sizeOnDisk > 0 else { return "Dynamic" }
        return ByteCountFormatter.string(fromByteCount: sizeOnDisk, countStyle: .file)
    }

    public var formattedLastUsed: String {
        guard let last = lastUsed else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: last, relativeTo: Date())
    }
}

// MARK: - Managed Windows Environment Model
public struct EnvironmentItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var name: String
    public var description: String
    public var prefixPath: String
    public var defaultRuntimeId: String
    public var architecture: String // "win64"
    public var isIsolated: Bool
    public var registryOverrides: [String: String]
    public var installedDependencies: [String]
    public var createdAt: Date

    public init(
        id: String,
        name: String,
        description: String = "",
        prefixPath: String,
        defaultRuntimeId: String = "forge_wine10",
        architecture: String = "win64",
        isIsolated: Bool = false,
        registryOverrides: [String: String] = [:],
        installedDependencies: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.prefixPath = prefixPath
        self.defaultRuntimeId = defaultRuntimeId
        self.architecture = architecture
        self.isIsolated = isIsolated
        self.registryOverrides = registryOverrides
        self.installedDependencies = installedDependencies
        self.createdAt = createdAt
    }
}

// MARK: - Compatibility Runtime Model
public struct RuntimeItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var name: String
    public var version: String
    public var architecture: String // "ARM64 + WoW64"
    public var runnerPath: String
    public var serverPath: String
    public var metalSupportLevel: String // "D3DMetal 2.0 (DirectX 11/12)"
    public var isDefault: Bool
    public var isHealthy: Bool

    public init(
        id: String,
        name: String,
        version: String,
        architecture: String = "Apple Silicon (ARM64/WoW64)",
        runnerPath: String,
        serverPath: String,
        metalSupportLevel: String = "Apple D3DMetal (DX11/DX12)",
        isDefault: Bool = false,
        isHealthy: Bool = true
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.architecture = architecture
        self.runnerPath = runnerPath
        self.serverPath = serverPath
        self.metalSupportLevel = metalSupportLevel
        self.isDefault = isDefault
        self.isHealthy = isHealthy
    }
}

// MARK: - Activity Event Model
public enum ActivitySeverity: String, Codable, Sendable {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"

    public var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    public var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

public struct ActivityEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let title: String
    public let details: String
    public let category: String // "Runtime", "Process", "Graphics", "Discovery", "Installation"
    public let severity: ActivitySeverity
    public let technicalLog: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        title: String,
        details: String,
        category: String = "Platform",
        severity: ActivitySeverity = .info,
        technicalLog: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.details = details
        self.category = category
        self.severity = severity
        self.technicalLog = technicalLog
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

// MARK: - Installation Manifest
public struct InstallationManifest: Identifiable, Codable, Sendable {
    public let id: String
    public var appName: String
    public var installerPath: String
    public var targetEnvironmentId: String
    public var requiredDependencies: [String]
    public var status: String
    public var completedSteps: [String]

    public init(
        id: String = UUID().uuidString,
        appName: String,
        installerPath: String,
        targetEnvironmentId: String = "default",
        requiredDependencies: [String] = [],
        status: String = "Pending",
        completedSteps: [String] = []
    ) {
        self.id = id
        self.appName = appName
        self.installerPath = installerPath
        self.targetEnvironmentId = targetEnvironmentId
        self.requiredDependencies = requiredDependencies
        self.status = status
        self.completedSteps = completedSteps
    }
}
