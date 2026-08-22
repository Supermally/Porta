import SwiftUI
import AppKit

public struct FloatingGlassSidebarView: View {
    @ObservedObject var engine: EngineService
    @Binding var isCollapsed: Bool

    public init(engine: EngineService, isCollapsed: Binding<Bool> = .constant(false)) {
        self.engine = engine
        self._isCollapsed = isCollapsed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // App Header Branding & Collapse Toggle
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.85), Color.indigo.opacity(0.95)],
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

                if !isCollapsed {
                    Text("Mac Gaming")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Collapse sidebar")
                }
            }
            .padding(.horizontal, isCollapsed ? 12 : 14)
            .padding(.top, 14)

            Divider()
                .opacity(0.15)
                .padding(.horizontal, 10)

            // Primary Navigation Items
            VStack(spacing: 4) {
                SidebarNavItem(
                    title: "Library",
                    icon: "square.grid.2x2",
                    badgeText: engine.games.count > 0 ? "\(engine.games.count)" : nil,
                    isCollapsed: isCollapsed,
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
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .discover
                ) {
                    engine.activeTab = .discover
                }
                .keyboardShortcut("2", modifiers: .command)

                SidebarNavItem(
                    title: "Compatibility",
                    icon: "checkmark.seal",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .compatibility
                ) {
                    engine.activeTab = .compatibility
                }
                .keyboardShortcut("3", modifiers: .command)

                SidebarNavItem(
                    title: "Downloads",
                    icon: "arrow.down.circle",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .downloads
                ) {
                    engine.activeTab = .downloads
                }
                .keyboardShortcut("4", modifiers: .command)

                SidebarNavItem(
                    title: "Console",
                    icon: "terminal",
                    badgeText: "\(engine.consoleLogs.count)",
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .console
                ) {
                    engine.activeTab = .console
                }
                .keyboardShortcut("d", modifiers: .command)
            }
            .padding(.horizontal, isCollapsed ? 6 : 8)

            // Storefronts Section (Only shown when expanded)
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Storefronts")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 4)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach([
                                StorefrontFilter.all,
                                StorefrontFilter.steam,
                                StorefrontFilter.gog,
                                StorefrontFilter.epic,
                                StorefrontFilter.local
                            ], id: \.self) { sf in
                                let count = countForStorefront(sf)
                                if count > 0 || sf == .all {
                                    SidebarStorefrontItem(
                                        title: sf.rawValue,
                                        icon: sf.icon,
                                        count: count,
                                        isSelected: engine.selectedStorefront == sf && engine.activeTab == .library
                                    ) {
                                        engine.selectedStorefront = sf
                                        engine.activeTab = .library
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            Divider()
                .opacity(0.15)
                .padding(.horizontal, 10)

            // Footer Settings & Expand Toggle
            VStack(spacing: 4) {
                SidebarNavItem(
                    title: "Settings",
                    icon: "gearshape",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .settings
                ) {
                    engine.activeTab = .settings
                }
                .keyboardShortcut(",", modifiers: .command)

                if isCollapsed {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .help("Expand sidebar")
                }
            }
            .padding(.horizontal, isCollapsed ? 6 : 8)
            .padding(.bottom, 12)
        }
        .frame(width: isCollapsed ? 56 : 220)
        .frame(maxHeight: .infinity)
        .crystalClearSidebarGlass(cornerRadius: 22)
        .padding(.leading, 14)
        .padding(.vertical, 14)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCollapsed)
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
    var isCollapsed: Bool = false
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

                if !isCollapsed {
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
            }
            .padding(.horizontal, isCollapsed ? 8 : 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 2)
                    } else if isHovered {
                        Capsule()
                            .fill(Color.white.opacity(0.09))
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
        .help(isCollapsed ? title : "")
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
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, y: 2)
                    } else if isHovered {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
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
