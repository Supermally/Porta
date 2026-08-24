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
            // App Header Branding & Collapse / Expand Toggle
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isCollapsed.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.9), Color.indigo.opacity(1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "cube.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .help("Porta • Powered by Forge Engine")

                if !isCollapsed {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Porta")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Forge Engine")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

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
                    title: "Home",
                    icon: "house.fill",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .home
                ) {
                    engine.activeTab = .home
                }
                .keyboardShortcut("1", modifiers: .command)

                SidebarNavItem(
                    title: "Applications",
                    icon: "square.grid.2x2.fill",
                    badgeText: engine.universalApplications.count > 0 ? "\(engine.universalApplications.count)" : nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .applications
                ) {
                    engine.activeTab = .applications
                }
                .keyboardShortcut("2", modifiers: .command)

                SidebarNavItem(
                    title: "Games",
                    icon: "gamecontroller.fill",
                    badgeText: engine.games.count > 0 ? "\(engine.games.count)" : nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .games || (engine.activeTab == .library && engine.selectedStorefront == .all)
                ) {
                    engine.activeTab = .games
                }
                .keyboardShortcut("3", modifiers: .command)

                SidebarNavItem(
                    title: "Runtimes",
                    icon: "cpu.fill",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .runtimes
                ) {
                    engine.activeTab = .runtimes
                }
                .keyboardShortcut("4", modifiers: .command)

                SidebarNavItem(
                    title: "Downloads",
                    icon: "arrow.down.circle.fill",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .downloads
                ) {
                    engine.activeTab = .downloads
                }
                .keyboardShortcut("5", modifiers: .command)

                SidebarNavItem(
                    title: "Activity",
                    icon: "chart.bar.xaxis",
                    badgeText: engine.activityEvents.count > 0 ? "\(engine.activityEvents.count)" : nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .activity
                ) {
                    engine.activeTab = .activity
                }
                .keyboardShortcut("6", modifiers: .command)
            }
            .padding(.horizontal, isCollapsed ? 6 : 8)

            Spacer()

            // Developer / Advanced Tools Section
            VStack(alignment: .leading, spacing: 4) {
                if !isCollapsed {
                    Text("Developer Tools")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                }

                SidebarNavItem(
                    title: "Debug Lab",
                    icon: "testtube.2",
                    badgeText: "Wine 10",
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .debugLab
                ) {
                    engine.activeTab = .debugLab
                }
                .keyboardShortcut("t", modifiers: .command)

                SidebarNavItem(
                    title: "Console",
                    icon: "terminal.fill",
                    badgeText: "\(engine.consoleLogs.count)",
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .console
                ) {
                    engine.activeTab = .console
                }
                .keyboardShortcut("d", modifiers: .command)

                SidebarNavItem(
                    title: "Settings",
                    icon: "gearshape.fill",
                    badgeText: nil,
                    isCollapsed: isCollapsed,
                    isSelected: engine.activeTab == .settings
                ) {
                    engine.activeTab = .settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding(.horizontal, isCollapsed ? 6 : 8)
            .padding(.bottom, 12)
        }
        .frame(width: isCollapsed ? 58 : 220)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    engine.glassConfig.enabled
                        ? (engine.glassConfig.variant == .clear ? Color.white.opacity(0.02) : Color.white.opacity(0.06))
                        : Color(NSColor.controlBackgroundColor)
                )
                .background(
                    engine.glassConfig.enabled
                        ? (engine.glassConfig.variant == .clear ? Material.ultraThinMaterial : Material.thinMaterial)
                        : Material.regularMaterial,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: Color.black.opacity(engine.glassConfig.enabled ? 0.22 : 0.12), radius: 16, x: 2, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    engine.glassConfig.enabled
                        ? LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(engine.glassConfig.variant == .clear ? 0.50 : 0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.06), location: 0.45),
                                .init(color: Color.white.opacity(0.22), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [Color.primary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.0
                )
        )
        .padding(.leading, 14)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCollapsed)
    }
}

// MARK: - Sidebar Nav Item Component
private struct SidebarNavItem: View {
    let title: String
    let icon: String
    let badgeText: String?
    let isCollapsed: Bool
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : (isHovered ? .primary : .secondary))
                    .frame(width: 20)

                if !isCollapsed {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)

                    Spacer()

                    if let badge = badgeText {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .white : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                            )
                    }
                }
            }
            .padding(.horizontal, isCollapsed ? 8 : 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.14) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear))
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = false } }
        )
    }
}
