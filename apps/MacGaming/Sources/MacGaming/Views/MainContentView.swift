import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()

    public var body: some View {
        NavigationSplitView {
            List(selection: $engine.activeTab) {
                Section {
                    NavigationLink(value: NavigationTab.library) {
                        Label {
                            HStack {
                                Text("Library")
                                Spacer()
                                if engine.games.count > 0 {
                                    Text("\(engine.games.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "square.grid.2x2")
                        }
                    }
                    .keyboardShortcut("1", modifiers: .command)

                    NavigationLink(value: NavigationTab.discover) {
                        Label("Discover", systemImage: "sparkles")
                    }
                    .keyboardShortcut("2", modifiers: .command)

                    NavigationLink(value: NavigationTab.compatibility) {
                        Label("Compatibility", systemImage: "checkmark.seal")
                    }
                    .keyboardShortcut("3", modifiers: .command)

                    NavigationLink(value: NavigationTab.downloads) {
                        Label("Downloads", systemImage: "arrow.down.circle")
                    }
                    .keyboardShortcut("4", modifiers: .command)
                }

                Section("Storefronts") {
                    ForEach(StorefrontFilter.allCases) { sf in
                        StorefrontSidebarRow(sf: sf, engine: engine)
                    }
                }

                Section {
                    NavigationLink(value: NavigationTab.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Mac Gaming")
            .frame(minWidth: 200, idealWidth: 220)
        } content: {
            Group {
                switch engine.activeTab {
                case .library:
                    LibraryView(engine: engine)
                        .frame(minWidth: 320, idealWidth: 380)
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
        } detail: {
            Group {
                if let game = engine.selectedGame, engine.activeTab == .library {
                    GameDetailView(engine: engine, game: game)
                } else if engine.activeTab == .discover {
                    DeveloperDemandView(engine: engine)
                } else if engine.activeTab == .compatibility {
                    LibraryAuditView(engine: engine)
                } else {
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
        }
        .frame(minWidth: 920, minHeight: 600)
    }
}

struct StorefrontSidebarRow: View {
    let sf: StorefrontFilter
    @ObservedObject var engine: EngineService

    private var isSelected: Bool {
        engine.activeTab == .library && engine.selectedStorefront == sf
    }

    private var count: Int {
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

    var body: some View {
        Button {
            engine.selectedStorefront = sf
            engine.activeTab = .library
        } label: {
            HStack {
                Label(sf.rawValue, systemImage: sf.icon)
                    .fontWeight(isSelected ? .semibold : .regular)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
