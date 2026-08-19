import SwiftUI
import AppKit

public struct FloatingGlassSidebarView: View {
    @ObservedObject var engine: EngineService

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Header Branding
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.blue.opacity(0.4), radius: 6, y: 2)

                Text("Mac Gaming")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            Divider()
                .opacity(0.2)
                .padding(.horizontal, 10)

            // Primary Navigation Items
            VStack(spacing: 4) {
                SidebarNavItem(
                    title: "Library",
                    icon: "square.grid.2x2",
                    badgeText: engine.games.count > 0 ? "\(engine.games.count)" : nil,
                    isSelected: engine.activeTab == .library && engine.selectedStorefront == .all
                ) {
                    engine.selectedStorefront = .all
                    engine.activeTab = .library
                }
                .keyboardShortcut("1", modifiers: .command)

                SidebarNavItem(
                    title: "Discover",
                    icon: "sparkles",
                    badgeText: nil,
                    isSelected: engine.activeTab == .discover
                ) {
                    engine.activeTab = .discover
                }
                .keyboardShortcut("2", modifiers: .command)

                SidebarNavItem(
                    title: "Compatibility",
                    icon: "checkmark.seal",
                    badgeText: nil,
                    isSelected: engine.activeTab == .compatibility
                ) {
                    engine.activeTab = .compatibility
                }
                .keyboardShortcut("3", modifiers: .command)

                SidebarNavItem(
                    title: "Downloads",
                    icon: "arrow.down.circle",
                    badgeText: nil,
                    isSelected: engine.activeTab == .downloads
                ) {
                    engine.activeTab = .downloads
                }
                .keyboardShortcut("4", modifiers: .command)
            }
            .padding(.horizontal, 8)

            // Storefronts Section
            VStack(alignment: .leading, spacing: 6) {
                Text("STOREFRONTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(StorefrontFilter.allCases.filter { $0 != .all }) { sf in
                            let count = countForStorefront(sf)
                            SidebarStorefrontItem(
                                title: sf.rawValue,
                                icon: sf.icon,
                                count: count,
                                isSelected: engine.activeTab == .library && engine.selectedStorefront == sf
                            ) {
                                engine.selectedStorefront = sf
                                engine.activeTab = .library
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)

            Divider()
                .opacity(0.2)
                .padding(.horizontal, 10)

            // Footer Settings
            VStack(spacing: 4) {
                SidebarNavItem(
                    title: "Settings",
                    icon: "gearshape",
                    badgeText: nil,
                    isSelected: engine.activeTab == .settings
                ) {
                    engine.activeTab = .settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(.leading, 14)
        .padding(.vertical, 14)
    }

    private func countForStorefront(_ sf: StorefrontFilter) -> Int {
        engine.games.filter { game in
            switch sf {
            case .all: return true
            case .steam: return game.storefront == "Steam"
            case .gog: return game.storefront == "GOG Galaxy"
            case .epic: return game.storefront == "Epic Games"
            case .itch: return game.storefront == "itch.io"
            case .ubisoft: return game.storefront == "Ubisoft"
            case .ea: return game.storefront == "EA App"
            case .battlenet: return game.storefront == "Battle.net"
            case .universalApp: return game.isUniversalApp
            case .local: return game.storefront.contains("Local")
            }
        }.count
    }
}

// MARK: - Sidebar Nav Item
private struct SidebarNavItem: View {
    let title: String
    let icon: String
    let badgeText: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0.05, green: 0.40, blue: 0.90)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(0.90), location: 0.0),
                                                .init(color: Color.white.opacity(0.20), location: 0.5),
                                                .init(color: Color.white.opacity(0.50), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.1
                                    )
                            )
                            .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 2)
                    } else if isHovered {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                            )
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(Capsule())
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Sidebar Storefront Item
private struct SidebarStorefrontItem: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.0)
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, y: 2)
                    } else if isHovered {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(Capsule())
            .scaleEffect(isHovered && !isSelected ? 1.015 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
