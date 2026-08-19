import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()

    public var body: some View {
        ZStack {
            // Ambient Chromatic Backdrop for Liquid Glass Refraction
            AmbientChromaticBackdrop()

            HStack(spacing: 0) {
                // 1. Floating Crystal-Clear Liquid Glass Sidebar
                FloatingGlassSidebarView(engine: engine)

                // 2. Content & Detail Canvas
                Group {
                    switch engine.activeTab {
                    case .library:
                        HSplitView {
                            LibraryView(engine: engine)
                                .frame(minWidth: 340, idealWidth: 420)

                            if let game = engine.selectedGame {
                                GameDetailView(engine: engine, game: game)
                                    .frame(minWidth: 400)
                            } else {
                                emptyStateView
                            }
                        }
                    case .discover:
                        MacNativeSpotlightView(engine: engine)
                    case .compatibility:
                        UniversalSearchView(engine: engine)
                    case .downloads:
                        DownloadsView(engine: engine)
                    case .settings:
                        SettingsView(engine: engine)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .liquidGlassEnvironment(enabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
        }
        .frame(minWidth: 960, minHeight: 640)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Game Selected")
                .font(.headline)
            Text("Select a game from your library to view details and launch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
