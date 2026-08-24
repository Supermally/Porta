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
                .opacity(0.12)

            // Main Content Area
            if filteredApplications.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
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
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.08))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .frame(maxWidth: 360)

                Spacer()

                // View Mode Switcher (Clean macOS Segmented Icons)
                HStack(spacing: 2) {
                    Button(action: { viewMode = .grid }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 13, weight: viewMode == .grid ? .semibold : .regular))
                            .foregroundColor(viewMode == .grid ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewMode == .grid ? Color.primary.opacity(0.12) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Grid View")

                    Button(action: { viewMode = .list }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13, weight: viewMode == .list ? .semibold : .regular))
                            .foregroundColor(viewMode == .list ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewMode == .list ? Color.primary.opacity(0.12) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("List View")
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )

                // Refresh discovery button
                Button(action: {
                    withAnimation(.spring(response: 0.35)) {
                        engine.refreshDiscoveredApplications()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.08))
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        )
                }
                .buttonStyle(.plain)
                .help("Refresh discovered applications from managed environments")

                // Install Button
                Button(action: { showingInstallSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Install Software")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            // Category Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ApplicationCategory.allCases) { cat in
                        Button(action: {
                            withAnimation(.spring(response: 0.25)) {
                                selectedCategory = cat
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 11))
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: selectedCategory == cat ? .semibold : .regular))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat ? Color.blue.opacity(0.20) : Color.secondary.opacity(0.08))
                                    .background(selectedCategory == cat ? .ultraThinMaterial : .ultraThinMaterial, in: Capsule())
                            )
                            .foregroundColor(selectedCategory == cat ? .blue : .primary)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCategory == cat
                                            ? LinearGradient(colors: [Color.blue.opacity(0.6), Color.indigo.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color.white.opacity(0.15), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 18)], spacing: 18) {
            ForEach(filteredApplications) { app in
                LiquidGlassAppCard(
                    app: app,
                    isSelected: engine.selectedApplication?.id == app.id,
                    onSelect: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            engine.selectedApplication = app
                        }
                    },
                    onLaunch: {
                        engine.launchApplication(app)
                    }
                )
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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        engine.selectedApplication = app
                    }
                }) {
                    HStack(spacing: 14) {
                        // Thumbnail
                        if let urlStr = app.headerImageUrl ?? app.iconUrl, let url = URL(string: urlStr) {
                            CachedArtworkImageView(
                                url: url,
                                contentMode: .fill,
                                placeholder: AnyView(
                                    Image(systemName: app.category.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue.opacity(0.1))
                                )
                            )
                            .frame(width: 44, height: 44)
                            .cornerRadius(8)
                            .clipped()
                        } else {
                            Image(systemName: app.category.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }

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
                            .frame(width: 130, alignment: .trailing)

                        Button(action: { engine.launchApplication(app) }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                                .padding(4)
                        }
                        .buttonStyle(.portaGlass(cornerRadius: 7, isProminent: true))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(engine.selectedApplication?.id == app.id ? Color.blue.opacity(0.12) : Color.secondary.opacity(0.04))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                engine.selectedApplication?.id == app.id
                                    ? Color.blue.opacity(0.4)
                                    : Color.primary.opacity(0.04),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
    }

    // MARK: - Empty State (None Found / None Imported)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: !searchQuery.isEmpty ? "magnifyingglass" : (selectedCategory != .all ? selectedCategory.icon : "cube.transparent"))
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 6) {
                Text(!searchQuery.isEmpty ? "None Found" : (selectedCategory != .all ? "No \(selectedCategory.rawValue) Software Found" : "None Imported"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(!searchQuery.isEmpty ? "No applications found matching \"\(searchQuery)\"." : (selectedCategory != .all ? "No applications have been imported in the \(selectedCategory.rawValue) category yet." : "No universal applications or Windows software have been imported yet."))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: 12) {
                if !searchQuery.isEmpty {
                    Button("Clear Search") {
                        searchQuery = ""
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 10))
                }

                if selectedCategory != .all {
                    Button("Show All Categories") {
                        selectedCategory = .all
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 10))
                }

                Button(action: { showingInstallSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Install Software…")
                    }
                }
                .buttonStyle(.portaGlass(cornerRadius: 10, isProminent: true))

                Button(action: { engine.refreshDiscoveredApplications() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.portaGlass(cornerRadius: 10))
                .help("Rescan managed environments")
            }
            .padding(.top, 6)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Rich Liquid Glass Application Card
private struct LiquidGlassAppCard: View {
    let app: AppItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onLaunch: () -> Void

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                headerArtworkView
                infoFooterView
            }
            .padding(10)
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : (isHovered ? Color.black.opacity(0.1) : Color.clear), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = false } }
        )
    }

    private var headerArtworkView: some View {
        ZStack(alignment: .topTrailing) {
            if let urlStr = app.headerImageUrl ?? app.iconUrl, let url = URL(string: urlStr) {
                CachedArtworkImageView(
                    url: url,
                    contentMode: .fill,
                    placeholder: AnyView(fallbackBanner)
                )
                .frame(maxWidth: .infinity, maxHeight: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                fallbackBanner
            }

            if app.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.45)))
                    .padding(6)
            }

            if isHovered {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onLaunch) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.blue))
                                .shadow(color: Color.blue.opacity(0.5), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var infoFooterView: some View {
        VStack(alignment: .leading, spacing: 3) {
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
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)

                Spacer()

                Text(app.graphicsApi.contains("D3DMetal") ? "D3DMetal" : (app.graphicsApi.contains("12") ? "DirectX 12" : "DirectX 11"))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.top, 2)
        }
        .frame(height: 54, alignment: .topLeading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? Color.blue.opacity(0.14) : (isHovered ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.03)))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(
                isSelected
                    ? LinearGradient(colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : (isHovered
                        ? LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.10), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)),
                lineWidth: isSelected ? 1.5 : 1.0
            )
    }

    private var fallbackBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.indigo.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: 110)

            Image(systemName: app.category.icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
    }
}
