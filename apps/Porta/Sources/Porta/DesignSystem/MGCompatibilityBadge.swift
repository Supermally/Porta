import SwiftUI

public struct MGCompatibilityBadge: View {
    public let badge: CompatibilityBadge
    public var isProminent: Bool

    public init(_ badge: CompatibilityBadge, isProminent: Bool = false) {
        self.badge = badge
        self.isProminent = isProminent
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor)

            Text(badge.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(statusColor.opacity(0.3), lineWidth: 0.8)
        )
    }

    private var iconName: String {
        switch badge {
        case .native: return "checkmark.seal.fill"
        case .compatible: return "checkmark.circle.fill"
        case .experimental: return "exclamationmark.triangle.fill"
        case .communityFix: return "wrench.and.screwdriver.fill"
        case .unsupported: return "xmark.octagon.fill"
        }
    }

    private var statusColor: Color {
        switch badge {
        case .native: return Color.green
        case .compatible: return Color.green
        case .experimental: return Color.orange
        case .communityFix: return Color.yellow
        case .unsupported: return Color.red
        }
    }
}
