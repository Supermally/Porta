import SwiftUI
import AppKit

public struct LibraryView: View {
    @ObservedObject var engine: EngineService
    var leadingInset: CGFloat = 248
    var trailingInset: CGFloat = 20

    private let gridColumns = [
        GridItem(.adaptive(minimum: 145, maximum: 210), spacing: 18)
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Top margin for floating top control bar
                Spacer().frame(height: 52)

                // Recently Played Shelf (Apple Horizontal Scrolling Under Sidebar)
                if engine.searchText.isEmpty && engine.selectedFilter == nil && engine.selectedStorefront == .all {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently Played")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.leading, leadingInset)
                            .padding(.trailing, trailingInset)

                        // Extends to leading 0 so scrolling cards slide UNDER the floating glass sidebar!
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(engine.games.prefix(6))) { game in
                                    RecentGamePosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    }
                                }
                            }
                            .padding(.leading, leadingInset)
                            .padding(.trailing, trailingInset)
                            .padding(.vertical, 4)
                        }
                    }
                }

                // All Games Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(engine.selectedStorefront == .all ? "All Games" : engine.selectedStorefront.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(engine.filteredGames.count) titles")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if engine.filteredGames.isEmpty {
                        emptyLibraryView
                    } else if engine.libraryViewMode == .grid {
                        LazyVGrid(columns: gridColumns, spacing: 22) {
                            ForEach(engine.filteredGames) { game in
                                GamePosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                    engine.selectedGame = game
                                }
                            }
                        }
                    } else {
                        LazyVStack(spacing: 6) {
                            ForEach(engine.filteredGames) { game in
                                GameListRow(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                    engine.selectedGame = game
                                } onPlay: {
                                    engine.launchGame(game)
                                }
                            }
                        }
                    }
                }
                .padding(.leading, leadingInset)
                .padding(.trailing, trailingInset)
            }
            .padding(.vertical, 20)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: leadingInset)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: trailingInset)
    }

    // MARK: - Empty State View (None Found / None Imported)
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 68, height: 68)
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 6) {
                Text(emptyStateTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(emptyStateSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: 12) {
                if !engine.searchText.isEmpty {
                    Button("Clear Search") {
                        engine.searchText = ""
                    }
                    .buttonStyle(.bordered)
                }

                if engine.selectedStorefront != .all {
                    Button("Show All Storefronts") {
                        engine.selectedStorefront = .all
                    }
                    .buttonStyle(.bordered)
                }

                if engine.selectedFilter != nil {
                    Button("Show All Tiers") {
                        engine.selectedFilter = nil
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    engine.openNativeFilePicker(chooseFolder: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Import Game…")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.top, 6)

            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var emptyStateIcon: String {
        if !engine.searchText.isEmpty {
            return "magnifyingglass"
        } else if engine.selectedStorefront != .all {
            return "tray"
        } else if engine.selectedFilter != nil {
            return "line.3.horizontal.decrease.circle"
        } else {
            return "gamecontroller"
        }
    }

    private var emptyStateTitle: String {
        if !engine.searchText.isEmpty {
            return "None Found"
        } else if engine.selectedStorefront != .all {
            return "No \(engine.selectedStorefront.rawValue) Titles Found"
        } else if let filter = engine.selectedFilter {
            return "No \(filter.rawValue) Games Found"
        } else {
            return "None Imported"
        }
    }

    private var emptyStateSubtitle: String {
        if !engine.searchText.isEmpty {
            return "No titles matched \"\(engine.searchText)\". Try adjusting your search query or clear filters."
        } else if engine.selectedStorefront != .all {
            return "No games have been imported or discovered for \(engine.selectedStorefront.rawValue) yet."
        } else if let filter = engine.selectedFilter {
            return "No games currently match the \(filter.rawValue) compatibility rating tier."
        } else {
            return "No games have been imported into Porta yet. Import a game folder or Windows executable to begin."
        }
    }
}

// MARK: - Artwork-First Game Poster Card
struct GamePosterCard: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster Artwork (2:3 Aspect Ratio)
                ZStack(alignment: .bottomTrailing) {
                    GameArtworkView(game: game, cornerRadius: 12)
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : (isHovered ? Color.white.opacity(0.3) : Color.clear), lineWidth: 2)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : (isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08)), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)

                // Typography & Semantic Compatibility Badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack {
                        Text(game.storefront)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CompatibilityBadgeView(game.badge)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scaleEffect(isHovered ? 1.025 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Recently Played Horizontal Poster Card
struct RecentGamePosterCard: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                GameWideBannerView(game: game, cornerRadius: 12)
                    .frame(width: 190, height: 115)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : (isHovered ? Color.white.opacity(0.3) : Color.clear), lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : (isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08)), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Text(game.storefront)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 190, alignment: .leading)
            }
            .scaleEffect(isHovered ? 1.025 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Game List Row
struct GameListRow: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 14) {
                GameArtworkView(game: game, cornerRadius: 6)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(game.developerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(game.storefront)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .leading)

                CompatibilityBadgeView(game.badge)

                Text("\(game.targetFps) FPS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)

                Button {
                    onPlay()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .padding(6)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wide Game Banner Loader Component (For Recently Played & Hero Shelves)
public struct GameWideBannerView: View {
    let game: GameItem
    let cornerRadius: CGFloat

    public var body: some View {
        Group {
            if let heroPath = game.localHeroPath ?? game.localPosterPath,
               let nsImage = NSImage(contentsOfFile: heroPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let appId = game.steamAppId, !appId.isEmpty {
                let heroURL = URL(string: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/library_hero.jpg")
                CachedArtworkImageView(
                    url: heroURL,
                    contentMode: .fill,
                    placeholder: AnyView(
                        CachedArtworkImageView(
                            url: URL(string: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/header.jpg"),
                            contentMode: .fill,
                            placeholder: AnyView(
                                CachedArtworkImageView(
                                    url: URL(string: game.steamHeaderImageURL ?? ""),
                                    contentMode: .fill,
                                    placeholder: AnyView(proceduralBanner)
                                )
                            )
                        )
                    )
                )
            } else if let headerURL = game.steamHeaderImageURL, let url = URL(string: headerURL) {
                CachedArtworkImageView(
                    url: url,
                    contentMode: .fill,
                    placeholder: AnyView(proceduralBanner)
                )
            } else {
                proceduralBanner
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var proceduralBanner: some View {
        ZStack {
            LinearGradient(
                colors: [game.bannerColor.opacity(0.85), Color.black.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.85))
                Text(game.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Game Image Loader Component
public struct GameArtworkView: View {
    let game: GameItem
    let cornerRadius: CGFloat

    public var body: some View {
        Group {
            if let localPath = game.localPosterPath ?? game.localHeroPath,
               let nsImage = NSImage(contentsOfFile: localPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if game.isNative, !game.executablePath.isEmpty,
                      FileManager.default.fileExists(atPath: game.executablePath) {
                let icon = NSWorkspace.shared.icon(forFile: game.executablePath)
                ZStack {
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.4), Color.black.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                }
            } else if let appId = game.steamAppId, !appId.isEmpty {
                let posterURL = URL(string: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/library_600x900.jpg")
                CachedArtworkImageView(
                    url: posterURL,
                    contentMode: .fill,
                    placeholder: AnyView(
                        Group {
                            if let headerURL = game.steamHeaderImageURL, let url = URL(string: headerURL) {
                                CachedArtworkImageView(
                                    url: url,
                                    contentMode: .fit,
                                    placeholder: AnyView(proceduralArtwork)
                                )
                                .padding(6)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.black.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            } else {
                                proceduralArtwork
                            }
                        }
                    )
                )
                .aspectRatio(2/3, contentMode: .fill)
            } else if let headerURL = game.steamHeaderImageURL, let url = URL(string: headerURL) {
                CachedArtworkImageView(
                    url: url,
                    contentMode: .fit,
                    placeholder: AnyView(proceduralArtwork)
                )
                .padding(4)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.black.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            } else {
                proceduralArtwork
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var proceduralArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [game.bannerColor.opacity(0.8), Color.black.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                Text(game.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(2)
            }
        }
    }
}
