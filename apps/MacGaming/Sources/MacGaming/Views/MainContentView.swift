import SwiftUI

public struct MainContentView: View {
    @StateObject var engine = EngineService()

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

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // Floating App Brand Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.gradient)
                            .frame(width: 28, height: 28)
                        Image(systemName: "apple.logo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 2)

                    Text("Mac Gaming")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 12)

                // Native Sidebar Glass Bubble Rows
                List {
                    Section {
                        SidebarTabRow(tab: .library, currentTab: $engine.activeTab, badgeCount: engine.games.count, engine: engine)
                            .keyboardShortcut("1", modifiers: .command)

                        SidebarTabRow(tab: .discover, currentTab: $engine.activeTab, engine: engine)
                            .keyboardShortcut("2", modifiers: .command)

                        SidebarTabRow(tab: .compatibility, currentTab: $engine.activeTab, engine: engine)
                            .keyboardShortcut("3", modifiers: .command)

                        SidebarTabRow(tab: .downloads, currentTab: $engine.activeTab, engine: engine)
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
                                        .font(.system(size: 13, weight: engine.activeTab == .library && engine.selectedStorefront == sf ? .semibold : .regular))
                                    Spacer()
                                    let count = countForStorefront(sf)
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 11, weight: .bold))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(engine.activeTab == .library && engine.selectedStorefront == sf ? Color.accentColor.opacity(0.18) : Color.clear)
                        }
                    }

                    Section {
                        SidebarTabRow(tab: .settings, currentTab: $engine.activeTab, engine: engine)
                            .keyboardShortcut(",", modifiers: .command)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 220, idealWidth: 240)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
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
            .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
        } detail: {
            Group {
                if let game = engine.selectedGame, engine.activeTab == .library {
                    GameDetailView(engine: engine, game: game)
                } else if engine.activeTab == .discover {
                    DeveloperDemandView(engine: engine)
                } else if engine.activeTab == .compatibility {
                    LibraryAuditView(engine: engine)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: engine.activeTab.icon)
                            .font(.system(size: 52))
                            .foregroundColor(.accentColor.opacity(0.8))
                            .padding(24)
                            .liquidGlassBubble(cornerRadius: 30, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                        Text(engine.activeTab == .library ? "Select a game from your library to view details and launch" : engine.activeTab.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 960, minHeight: 620)
    }
}

struct SidebarTabRow: View {
    let tab: NavigationTab
    @Binding var currentTab: NavigationTab
    var badgeCount: Int? = nil
    var engine: EngineService

    var body: some View {
        Button(action: { currentTab = tab }) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: currentTab == tab ? .bold : .regular))
                    .foregroundColor(currentTab == tab ? .accentColor : .primary)
                    .frame(width: 20)

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: currentTab == tab ? .semibold : .regular))
                    .foregroundColor(.primary)

                Spacer()

                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(currentTab == tab ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}
