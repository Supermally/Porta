import Foundation
import SwiftUI

public enum StorefrontFilter: String, CaseIterable, Identifiable {
    case all = "All Items"
    case steam = "Steam"
    case gog = "GOG Galaxy"
    case epic = "Epic Games"
    case itch = "itch.io"
    case ubisoft = "Ubisoft"
    case ea = "EA App"
    case battlenet = "Battle.net"
    case universalApp = "Universal Apps"
    case local = "Local / Custom"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .steam: return "gamecontroller.fill"
        case .gog: return "globe.americas.fill"
        case .epic: return "bolt.circle.fill"
        case .itch: return "cube.transparent.fill"
        case .ubisoft: return "circle.grid.cross.fill"
        case .ea: return "play.circle.fill"
        case .battlenet: return "flame.fill"
        case .universalApp: return "macwindow.badge.plus"
        case .local: return "folder.fill"
        }
    }
}

public enum SteamLaunchMode: String, CaseIterable, Identifiable {
    case virtualDesktop = "Virtual Desktop Container (Recommended)"
    case miniLibrary = "Mini Library Mode (Fast)"
    case standard = "Direct Win32 Window"
    case gamepadUI = "Gamepad / Big Picture Mode"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .virtualDesktop: return "display"
        case .miniLibrary: return "list.bullet.rectangle"
        case .standard: return "app.window.checkmark"
        case .gamepadUI: return "gamecontroller"
        }
    }

    public var description: String {
        switch self {
        case .virtualDesktop: return "Runs in a managed Wine virtual desktop to ensure 100% visible CEF UI without black screens."
        case .miniLibrary: return "Ultra-fast native list mode that skips heavy CEF webviews."
        case .standard: return "Direct native Cocoa window mode."
        case .gamepadUI: return "Modern console-style Big Picture UI optimized for controllers."
        }
    }
}

public enum CompatibilityBadge: String, CaseIterable, Identifiable, Codable, Sendable {
    case native = "Native"
    case compatible = "Ready"
    case experimental = "Tested"
    case communityFix = "Fix Required"
    case unsupported = "Blocked"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .native: return "checkmark.seal.fill"
        case .compatible: return "bolt.horizontal.fill"
        case .experimental: return "exclamationmark.triangle.fill"
        case .communityFix: return "wrench.adjustable.fill"
        case .unsupported: return "xmark.octagon.fill"
        }
    }

    public var icon: String { iconName }

    public var color: Color {
        switch self {
        case .native: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .compatible: return Color(red: 0.18, green: 0.50, blue: 0.98)
        case .experimental: return Color(red: 0.95, green: 0.77, blue: 0.06)
        case .communityFix: return Color(red: 0.98, green: 0.55, blue: 0.00)
        case .unsupported: return Color(red: 0.92, green: 0.23, blue: 0.25)
        }
    }

    public var actionTitle: String {
        switch self {
        case .native: return "Launch Native"
        case .compatible: return "Launch with Mac Gaming"
        case .experimental: return "Launch (Experimental)"
        case .communityFix: return "Apply Community Profile & Launch"
        case .unsupported: return "Blocked (Anti-Cheat / Driver)"
        }
    }
}

public enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case grid = "Grid"
    case list = "List"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case library = "Library"
    case discover = "Discover"
    case compatibility = "Compatibility"
    case downloads = "Downloads"
    case console = "Console"
    case settings = "Settings"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .library: return "square.stack.3d.up.fill"
        case .discover: return "sparkles"
        case .compatibility: return "checklist.checked"
        case .downloads: return "arrow.down.circle.fill"
        case .console: return "terminal.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var keyboardShortcut: KeyEquivalent {
        switch self {
        case .library: return "1"
        case .discover: return "2"
        case .compatibility: return "3"
        case .downloads: return "4"
        case .console: return "d"
        case .settings: return ","
        }
    }
}

public enum LogLevel: String, CaseIterable, Identifiable, Sendable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case process = "PROC"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .process: return "terminal.fill"
        }
    }
    public var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .process: return .green
        }
    }
}

public struct ConsoleLogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let source: String
    public let message: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), level: LogLevel = .info, source: String = "Engine", message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.source = source
        self.message = message
    }
}

public struct GameItem: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    public let storefront: String
    public var badge: CompatibilityBadge
    public let isNative: Bool
    public let isUniversalApp: Bool
    public let bannerColor: Color
    public var runtime: String
    public let rating: Int
    public let performanceStars: Int
    public let hardwarePreset: String
    public let targetFps: Int
    public let knownIssues: [String]
    public let antiCheatStatus: String?
    public var executablePath: String = ""
    public var installPath: String = ""
    public var displayResolution: String = "Native"
    public var configUtilityPath: String? = nil
    public var companionPrograms: [CompanionProgram] = []
    public var acquisitionType: AcquisitionType = .storefrontIntegration
    public var customLaunchArgs: String = ""
    public var isUnityGame: Bool = false
    public var engineType: String = "Auto"
    public var analysisChecklist: [String] = []
    public var steamAppId: String? = nil
    public var steamHeaderImageURL: String? = nil
    public var localPosterPath: String? = nil
    public var localHeroPath: String? = nil
    public var localLogoPath: String? = nil
    public var cloudSavePath: String? = nil
    public var developerName: String = "Official Release"
    public var lastPlayedText: String = "Recently"
    public var supportsController: Bool = true
    
    // Runtime override options
    public var useD3DMetal: Bool = true
    public var enableHud: Bool = false
    public var enableEsync: Bool = true
    public var enableFsync: Bool = true
}

public struct SteamAccountSummary: Identifiable, Hashable, Sendable {
    public var id: String { steamId }
    public let steamId: String
    public let accountName: String
    public let personaName: String
    public let isOnline: Bool
}

public enum AcquisitionType: String, CaseIterable, Hashable, Sendable {
    case nativeStorefront = "Native Storefront"
    case storefrontIntegration = "Storefront Integration"
    case windowsLauncherRuntime = "Windows Launcher Sandbox"
    case existingFiles = "Transferred PC Files / Folder"

    public var icon: String {
        switch self {
        case .nativeStorefront: return "applelogo"
        case .storefrontIntegration: return "arrow.down.circle.fill"
        case .windowsLauncherRuntime: return "shippingbox.fill"
        case .existingFiles: return "folder.badge.gearshape"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .nativeStorefront: return .green
        case .storefrontIntegration: return .blue
        case .windowsLauncherRuntime: return .purple
        case .existingFiles: return .teal
        }
    }
}

public struct CompanionProgram: Identifiable, Hashable, Sendable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var isEnabled: Bool = true
    public var launchDelaySeconds: Double = 0.0

    public init(name: String, path: String, isEnabled: Bool = true, launchDelaySeconds: Double = 0.0) {
        self.name = name
        self.path = path
        self.isEnabled = isEnabled
        self.launchDelaySeconds = launchDelaySeconds
    }
}

public struct HostHardwareInfo {
    public let chipName: String
    public let coreCount: Int
    public let memoryGB: Int
    public let osVersion: String
    public let osBuild: String
    public let isAppleSilicon: Bool
    public let metalSupported: Bool
    public let metalVersion: String
    public let rosettaReady: Bool
    public let controllerReady: Bool
}

public struct DiagnosticFindingItem: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let severity: String
    public let description: String
    public let logSnippet: String?
    public let recommendedAction: String
    public let autoFixCommand: String?
}

public struct DiagnosticReportItem: Hashable {
    public let summary: String
    public let hasCriticalIssues: Bool
    public let findings: [DiagnosticFindingItem]
}

public struct CommunityReviewItem: Identifiable, Hashable {
    public let id = UUID()
    public let userHandle: String
    public let tierName: String
    public let tierColor: Color
    public let ratingStars: Int
    public let chipName: String
    public let comment: String
    public var upvotes: Int
    public var isVerified: Bool
}

public struct BenchmarkSample: Identifiable, Hashable {
    public let id = UUID()
    public let timestampSec: Double
    public let fps: Double
    public let frametimeMs: Double
    public let gpuLoadPct: Double
}

public struct CatalogGameItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let isNative: Bool
    public let compatibilityTier: String
    public let storefronts: [String]
    public let recommendation: String
    public let recommendationReason: String
    public let targetFps: Int
    public let knownIssues: [String]
    public let antiCheat: String?
    public var requestCount: Int
    public var hasUserRequested: Bool = false
}

public struct AuditReportItem: Hashable, Sendable {
    public let totalGames: Int
    public let nativeCount: Int
    public let nativePct: Int
    public let compatibleCount: Int
    public let compatiblePct: Int
    public let experimentalCount: Int
    public let experimentalPct: Int
    public let unsupportedCount: Int
    public let unsupportedPct: Int
    public let translationReliancePct: Int
    public let headlineInsight: String
    public let developerCallout: String
}

public struct NativeSpotlightItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let studio: String
    public let bannerTag: String
    public let metalTechnologies: [String]
    public let description: String
    public let performanceHighlight: String
}

public struct DemandCampaignItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let publisher: String
    public var totalRequests: Int
    public let status: String
    public let commercialEstimate: String
    public var hasVoted: Bool = false
}
