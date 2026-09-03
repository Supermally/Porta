import SwiftUI

public struct MainContentView: View {
    @ObservedObject var engine = EngineService.shared
    @StateObject var setupManager = SetupManager.shared

    @State private var isSidebarCollapsed: Bool = false
    @State private var isTopBarCollapsed: Bool = false
    @State private var isDetailPanelOpen: Bool = true

    public var body: some View {
        Group {
            if !setupManager.isSetupCompleted {
                SetupView(setupManager: setupManager)
                    .transition(.opacity)
            } else {
                mainInterfaceView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: setupManager.isSetupCompleted)
    }

    private var leadingPadding: CGFloat {
        isSidebarCollapsed ? 80 : 248
    }

    private var mainInterfaceView: some View {
        GeometryReader { geometry in
            let windowWidth = geometry.size.width
            let isAutoCollapsed = isSidebarCollapsed || windowWidth < 1020
            let effectiveLeadingPadding: CGFloat = isAutoCollapsed ? 80 : 248
            let gameDetailWidth: CGFloat = min(380, max(300, windowWidth * 0.34))
            let appDetailWidth: CGFloat = min(340, max(280, windowWidth * 0.30))

            ZStack(alignment: .topLeading) {
                // 1. Native macOS Window Canvas Background
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()

                // 2. Full-Bleed Content Canvas with Dynamic Responsive Insets
                Group {
                    switch engine.activeTab {
                    case .home:
                        HomeView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .applications:
                        ApplicationsView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, (isDetailPanelOpen && engine.selectedApplication != nil) ? (appDetailWidth + 20) : 16)
                    case .games, .library:
                        LibraryView(
                            engine: engine,
                            leadingInset: effectiveLeadingPadding,
                            trailingInset: (isDetailPanelOpen && engine.selectedGame != nil) ? (gameDetailWidth + 24) : 20
                        )
                    case .runtimes:
                        RuntimesView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .downloads:
                        DownloadsView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .activity:
                        ActivityView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .discover:
                        MacNativeSpotlightView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .compatibility:
                        UniversalSearchView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .console:
                        DeveloperConsoleView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .debugLab:
                        DebugLabView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .acx:
                        ACXDiagnosticsView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    case .settings:
                        SettingsView(engine: engine)
                            .padding(.leading, effectiveLeadingPadding)
                            .padding(.trailing, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 3. Detached Floating Liquid Glass Top Control Bar
                if engine.activeTab == .library || engine.activeTab == .games {
                    HStack {
                        Spacer()
                        FloatingTopGlassBar(engine: engine, isCollapsed: $isTopBarCollapsed)
                            .padding(.top, 14)
                        Spacer()
                    }
                    .padding(.leading, isAutoCollapsed ? 70 : 230)
                    .padding(.trailing, (isDetailPanelOpen && engine.selectedGame != nil) ? (gameDetailWidth + 20) : 30)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isAutoCollapsed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDetailPanelOpen)
                }

                // 4. Detached Floating Collapsible Sidebar (Left)
                FloatingGlassSidebarView(
                    engine: engine,
                    isCollapsed: Binding(
                        get: { isAutoCollapsed },
                        set: { isSidebarCollapsed = $0 }
                    )
                )

                // 5. Universal Application Inspector Panel (Right)
                if let app = engine.selectedApplication, engine.activeTab == .applications, isDetailPanelOpen {
                    HStack {
                        Spacer()
                        ApplicationDetailView(engine: engine, app: app) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = false
                            }
                        }
                        .frame(width: appDetailWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                // 6. Detached Floating Game Detail Inspector Panel (Right)
                if let game = engine.selectedGame, (engine.activeTab == .library || engine.activeTab == .games), isDetailPanelOpen {
                    HStack {
                        Spacer()
                        FloatingDetailGlassPanel(engine: engine, game: game, panelWidth: gameDetailWidth) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = false
                            }
                        }
                    }
                }
            }
            .liquidGlassConfiguration(engine.glassConfig)
            .frame(minWidth: 720, minHeight: 480)
            .onChange(of: engine.selectedGame) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDetailPanelOpen = true
                }
            }
            .onChange(of: engine.selectedApplication) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDetailPanelOpen = true
                }
            }
        }
    }
}
