import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()
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

    private var mainInterfaceView: some View {
        ZStack(alignment: .topLeading) {
            // 1. Native macOS Window Canvas Background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            // 2. Full-Bleed Content Canvas
            Group {
                switch engine.activeTab {
                case .library:
                    LibraryView(
                        engine: engine,
                        leadingInset: isSidebarCollapsed ? 80 : 248,
                        trailingInset: (isDetailPanelOpen && engine.selectedGame != nil) ? 470 : 20
                    )
                case .discover:
                    MacNativeSpotlightView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                case .compatibility:
                    UniversalSearchView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                case .downloads:
                    DownloadsView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                case .console:
                    DeveloperConsoleView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                case .debugLab:
                    DebugLabView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                case .settings:
                    SettingsView(engine: engine)
                        .padding(.leading, isSidebarCollapsed ? 80 : 248)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. Detached Floating Liquid Glass Top Control Bar
            if engine.activeTab == .library {
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

            // 5. Detached Floating Game Detail Inspector Panel (Right)
            if let game = engine.selectedGame, engine.activeTab == .library {
                HStack {
                    Spacer()
                    if isDetailPanelOpen {
                        FloatingDetailGlassPanel(engine: engine, game: game) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isDetailPanelOpen = false
                            }
                        }
                    } else {
                        // Collapsed Inspector Re-open Pill (Docked cleanly below the top control bar)
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
                        .padding(.top, 68) // Positioned with full clearance below top bar
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .liquidGlassConfiguration(engine.glassConfig)
        .frame(minWidth: 980, minHeight: 640)
    }
}
