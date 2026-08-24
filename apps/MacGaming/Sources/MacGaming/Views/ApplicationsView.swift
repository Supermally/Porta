import SwiftUI

public struct ApplicationsView: View {
    @ObservedObject var engine: EngineService
    @State private var searchQuery: String = ""
    @State private var selectedCategory: ApplicationCategory = .all
    @State private var viewMode: ViewMode = .grid
    @State private var showingInstallSheet: Bool = false

    public init(engine: EngineService) {
        self.engine = engine
    }

    private var filteredApplications: [AppItem] {
        engine.universalApplications.filter { app in
            let matchesCategory: Bool
            switch selectedCategory {
            case .all: matchesCategory = true
            case .recent: matchesCategory = app.lastUsed != nil
            case .favorites: matchesCategory = app.isFavorite
            default: matchesCategory = app.category == selectedCategory
            }

            let matchesQuery = searchQuery.isEmpty ||
                app.name.localizedCaseInsensitiveContains(searchQuery) ||
                app.publisher.localizedCaseInsensitiveContains(searchQuery) ||
                app.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })

            return matchesCategory && matchesQuery
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar Header
            toolbarHeader

            Divider()

            // Main Content Area
            if filteredApplications.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    if viewMode == .grid {
                        gridContent
                    } else {
                        listContent
                    }
                }
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            UniversalInstallationSheet(engine: engine)
        }
    }

    // MARK: - Toolbar Header
    private var toolbarHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search applications, tools, and games...", text: $searchQuery)
                        .textFieldStyle(.plain)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
                .frame(maxWidth: 360)

                Spacer()

                // View Mode Switcher
                Picker("View", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)

                // Refresh discovery button
                Button(action: { engine.refreshDiscoveredApplications() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("Refresh discovered applications from managed environments")

                // Install Button
                Button(action: { showingInstallSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Install Software")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            // Category Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ApplicationCategory.allCases) { cat in
                        Button(action: { selectedCategory = cat }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 11))
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: selectedCategory == cat ? .semibold : .regular))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? Color.blue.opacity(0.18) : Color.secondary.opacity(0.08))
                            .foregroundColor(selectedCategory == cat ? .blue : .primary)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedCategory == cat ? Color.blue.opacity(0.35) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Grid View
    private var gridContent: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 18)], spacing: 18) {
            ForEach(filteredApplications) { app in
                Button(action: {
                    engine.selectedApplication = app
                }) {
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(engine.selectedApplication?.id == app.id ? Color.blue.opacity(0.25) : Color.secondary.opacity(0.08))
                                .frame(height: 110)

                            Image(systemName: app.category.icon)
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if app.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                    .padding(8)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(app.publisher)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            HStack {
                                Text(app.category.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                                Spacer()
                                Text(app.graphicsApi)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(10)
                    .background(engine.selectedApplication?.id == app.id ? Color.blue.opacity(0.08) : Color.clear)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(engine.selectedApplication?.id == app.id ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Open") { engine.launchApplication(app) }
                    Button("Toggle Favorite") { engine.toggleFavorite(for: app) }
                    Divider()
                    Button("Reveal in Finder") { engine.revealApplicationInFinder(app) }
                    Button("Remove", role: .destructive) { engine.removeApplication(app) }
                }
            }
        }
        .padding(24)
    }

    // MARK: - List View
    private var listContent: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredApplications) { app in
                Button(action: {
                    engine.selectedApplication = app
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: app.category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(app.publisher)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(app.category.rawValue)
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(6)

                        Text(app.graphicsApi)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .trailing)

                        Button(action: { engine.launchApplication(app) }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                                .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(engine.selectedApplication?.id == app.id ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No applications found")
                .font(.system(size: 16, weight: .semibold))
            Text("Install software using the button above or refresh discovered applications.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
