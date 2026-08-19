import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case library = "My Games"
    case search = "Universal Search"
    case audit = "Library Audit"
    case spotlight = "Mac Native Spotlight"
    case campaigns = "Studio Demand Campaigns"
    case diagnostics = "Diagnostics & Hardware"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .library: return "gamecontroller.fill"
        case .search: return "magnifyingglass.circle.fill"
        case .audit: return "chart.pie.fill"
        case .spotlight: return "applelogo"
        case .campaigns: return "megaphone.fill"
        case .diagnostics: return "waveform.path.ecg"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainContentView: View {
    @StateObject var engine = EngineService()
    @State private var activeTab: NavigationTab = .library

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // App Brand
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16))
                    Text("Mac Gaming")
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                Divider()

                // Sidebar Navigation
                List(NavigationTab.allCases, id: \.self, selection: $activeTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 210, idealWidth: 230)
        } content: {
            switch activeTab {
            case .library:
                LibraryView(engine: engine)
                    .searchable(text: $engine.searchText, prompt: "Search games...")
                    .frame(minWidth: 280, idealWidth: 320)
            case .search:
                UniversalSearchView(engine: engine)
            case .audit:
                LibraryAuditView(engine: engine)
            case .spotlight:
                MacNativeSpotlightView(engine: engine)
            case .campaigns:
                DeveloperDemandView(engine: engine)
            case .diagnostics:
                DiagnosticsView(engine: engine)
            case .settings:
                SettingsView()
            }
        } detail: {
            if let game = engine.selectedGame, activeTab == .library {
                GameDetailView(engine: engine, game: game)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: activeTab.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(activeTab == .library ? "Select a game from the library to view details and launch" : "Mac Gaming Platform")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
