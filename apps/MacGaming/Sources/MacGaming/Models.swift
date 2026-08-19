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

    public var color: Color {
        switch self {
        case .native: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .compatible: return Color(red: 0.18, green: 0.50, blue: 0.98)
        case .experimental: return Color(red: 0.95, green: 0.77, blue: 0.06)
        case .communityFix: return Color(red: 0.98, green: 0.55, blue: 0.00)
        case .unsupported: return Color(red: 0.92, green: 0.26, blue: 0.21)
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
    
    // Runtime override options
    public var useD3DMetal: Bool = true
    public var enableHud: Bool = false
    public var enableEsync: Bool = true
    public var enableFsync: Bool = true
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
