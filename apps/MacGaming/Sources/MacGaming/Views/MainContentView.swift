import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // Native macOS App Header
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Mac Gaming")
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 12)

                // Native Sidebar Sections (Finder / Apple Music Style)
                List {
                    Section {
                        SidebarTabRow(tab: .library, currentTab: $engine.activeTab, badgeCount: engine.games.count)
                            .keyboardShortcut("1", modifiers: .command)

                        SidebarTabRow(tab: .discover, currentTab: $engine.activeTab)
                            .keyboardShortcut("2", modifiers: .command)

                        SidebarTabRow(tab: .compatibility, currentTab: $engine.activeTab)
                            .keyboardShortcut("3", modifiers: .command)

                        SidebarTabRow(tab: .downloads, currentTab: $engine.activeTab)
                            .keyboardShortcut("4", modifiers: .command)
                    }

                    Section("Game Providers") {
                        ForEach(StorefrontFilter.allCases) { sf in
                            Button(action: {
                                engine.selectedStorefront = sf
                                engine.activeTab = .library
                            }) {
                                HStack {
                                    Label(sf.rawValue, systemImage: sf.icon)
                                        .font(.system(size: 13))
                                    Spacer()
                                    let count = engine.games.filter {
                                        switch sf {
                                        case .all: return true
                                        case .steam: return $0.storefront == "Steam"
                                        case .gog: return $0.storefront == "GOG Galaxy"
                                        case .epic: return $0.storefront == "Epic Games"
                                        case .itch: return $0.storefront == "itch.io"
                                        case .ubisoft: return $0.storefront == "Ubisoft"
                                        case .ea: return $0.storefront == "EA App"
                                        case .battlenet: return $0.storefront == "Battle.net"
                                        case .universalApp: return $0.isUniversalApp
                                        case .local: return $0.storefront.contains("Local")
                                        }
                                    }.count
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(engine.activeTab == .library && engine.selectedStorefront == sf ? Color.accentColor.opacity(0.15) : Color.clear)
                        }
                    }

                    Section {
                        SidebarTabRow(tab: .settings, currentTab: $engine.activeTab)
                            .keyboardShortcut(",", modifiers: .command)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 220, idealWidth: 240)
            .background(.ultraThinMaterial)
            .resizeCursorOnTrailingEdge()
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
            .resizeCursorOnTrailingEdge()
        } detail: {
            if let game = engine.selectedGame, engine.activeTab == .library {
                GameDetailView(engine: engine, game: game)
            } else if engine.activeTab == .discover {
                DeveloperDemandView(engine: engine)
            } else if engine.activeTab == .compatibility {
                LibraryAuditView(engine: engine)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: engine.activeTab.icon)
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(engine.activeTab == .library ? "Select a game from your library to view details and launch" : engine.activeTab.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(minWidth: 960, minHeight: 620)
    }
}

struct SidebarTabRow: View {
    let tab: NavigationTab
    @Binding var currentTab: NavigationTab
    var badgeCount: Int? = nil

    var body: some View {
        Button(action: { currentTab = tab }) {
            HStack {
                Label(tab.rawValue, systemImage: tab.icon)
                    .font(.system(size: 13, weight: currentTab == tab ? .semibold : .regular))
                Spacer()
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.08))
                        .foregroundColor(.secondary)
                        .cornerRadius(10)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(currentTab == tab ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}
