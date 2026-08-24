import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()
    @StateObject var setupManager = SetupManager.shared

    @State private var isSidebarCollapsed: Bool = false
    @State private var isTopBarCollapsed: Bool = false
    @State private var isDetailPanelOpen: Bool = true
    @State private var isLaunchLoading: Bool = true

    public var body: some View {
        Group {
            if isLaunchLoading {
                LaunchLoadingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isLaunchLoading = false
                    }
                }
                .transition(.opacity)
            } else if !setupManager.isSetupCompleted {
                SetupView(setupManager: setupManager)
                    .transition(.opacity)
            } else {
                mainInterfaceView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isLaunchLoading)
        .animation(.easeInOut(duration: 0.3), value: setupManager.isSetupCompleted)
    }

    private var leadingPadding: CGFloat {
        isSidebarCollapsed ? 80 : 248
    }

    private var mainInterfaceView: some View {
        ZStack(alignment: .topLeading) {
            // 1. Native macOS Window Canvas Background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            // 2. Full-Bleed Content Canvas
            Group {
                switch engine.activeTab {
                case .home:
                    HomeView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .applications:
                    ApplicationsView(engine: engine)
                        .padding(.leading, leadingPadding)
                        .padding(.trailing, (isDetailPanelOpen && engine.selectedApplication != nil) ? 340 : 10)
                case .games, .library:
                    LibraryView(
                        engine: engine,
                        leadingInset: leadingPadding,
                        trailingInset: (isDetailPanelOpen && engine.selectedGame != nil) ? 470 : 20
                    )
                case .runtimes:
                    RuntimesView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .downloads:
                    DownloadsView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .activity:
                    ActivityView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .discover:
                    MacNativeSpotlightView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .compatibility:
                    UniversalSearchView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .console:
                    DeveloperConsoleView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .debugLab:
                    DebugLabView(engine: engine)
                        .padding(.leading, leadingPadding)
                case .settings:
                    SettingsView(engine: engine)
                        .padding(.leading, leadingPadding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. Detached Floating Liquid Glass Top Control Bar (Only for legacy Games library)
            if engine.activeTab == .library || engine.activeTab == .games {
                HStack {
                    Spacer()
                    FloatingTopGlassBar(engine: engine, isCollapsed: $isTopBarCollapsed)
                        .padding(.top, 14)
                    Spacer()
                }
                .padding(.leading, isSidebarCollapsed ? 70 : 230)
                .padding(.trailing, (isDetailPanelOpen && engine.selectedGame != nil) ? 460 : 30)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSidebarCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDetailPanelOpen)
            }

            // 4. Detached Floating Collapsible Sidebar (Left)
            FloatingGlassSidebarView(engine: engine, isCollapsed: $isSidebarCollapsed)

            // 5. Universal Application Inspector Panel (Right)
            if let app = engine.selectedApplication, engine.activeTab == .applications {
                HStack {
                    Spacer()
                    if isDetailPanelOpen {
                        ApplicationDetailView(engine: engine, app: app) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = false
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        // Collapsed Application Inspector Re-open Pill
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sidebar.right")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Details")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .shadow(color: Color.black.opacity(0.14), radius: 10, y: 4)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // 6. Detached Floating Game Detail Inspector Panel (Right)
            if let game = engine.selectedGame, (engine.activeTab == .library || engine.activeTab == .games) {
                HStack {
                    Spacer()
                    if isDetailPanelOpen {
                        FloatingDetailGlassPanel(engine: engine, game: game) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = false
                            }
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sidebar.right")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Details")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .background(.regularMaterial, in: Capsule())
                                    .shadow(color: Color.black.opacity(0.14), radius: 10, y: 4)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                        .padding(.top, 68)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .liquidGlassConfiguration(engine.glassConfig)
        .frame(minWidth: 980, minHeight: 640)
    }
}
