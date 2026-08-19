import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()

    public var body: some View {
        ZStack(alignment: .leading) {
            // 1. Full-Window Ambient Backdrop (Canvas Background)
            AmbientChromaticBackdrop()

            // 2. Full-Bleed Content Canvas (Extends edge-to-edge behind the floating sidebar)
            Group {
                switch engine.activeTab {
                case .library:
                    HSplitView {
                        LibraryView(engine: engine)
                            .frame(minWidth: 340, idealWidth: 440)

                        if let game = engine.selectedGame {
                            GameDetailView(engine: engine, game: game)
                                .frame(minWidth: 400)
                        } else {
                            emptyStateView
                        }
                    }
                case .discover:
                    MacNativeSpotlightView(engine: engine)
                        .padding(.leading, 248)
                case .compatibility:
                    UniversalSearchView(engine: engine)
                        .padding(.leading, 248)
                case .downloads:
                    DownloadsView(engine: engine)
                        .padding(.leading, 248)
                case .settings:
                    SettingsView(engine: engine)
                        .padding(.leading, 248)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. Floating Crystal-Clear Liquid Glass Sidebar (Floats Over the Content Canvas)
            FloatingGlassSidebarView(engine: engine)
        }
        .liquidGlassEnvironment(
            enabled: engine.liquidGlassEnabled,
            transparency: engine.glassTransparency,
            specularIntensity: engine.glassSpecularIntensity,
            blurRadius: engine.glassBlurRadius,
            reduceTransparency: engine.reduceTransparency
        )
        .frame(minWidth: 980, minHeight: 640)
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
