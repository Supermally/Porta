import SwiftUI
import AppKit

public struct LibraryView: View {
    @ObservedObject var engine: EngineService

    private let gridColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Recently Played Shelf (Apple Horizontal Scrolling Under Sidebar)
                if engine.searchText.isEmpty && engine.selectedFilter == nil && engine.selectedStorefront == .all {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently Played")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.leading, 248)
                            .padding(.trailing, 20)

                        // Extends to leading 0 so scrolling cards slide UNDER the floating glass sidebar!
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(engine.games.prefix(6))) { game in
                                    RecentGamePosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    }
                                }
                            }
                            .padding(.leading, 248)
                            .padding(.trailing, 20)
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

                    if engine.libraryViewMode == .grid {
                        LazyVGrid(columns: gridColumns, spacing: 22) {
                            ForEach(engine.filteredGames) { game in
                                GamePosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                    engine.selectedGame = game
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 6) {
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
                .padding(.leading, 248)
                .padding(.trailing, 20)
            }
            .padding(.vertical, 20)
        }
        .searchable(text: $engine.searchText, prompt: "Search library...")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("View Mode", selection: $engine.libraryViewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Menu {
                    Button {
                        engine.openNativeFilePicker(chooseFolder: true)
                    } label: {
                        Label("Import Game Folder...", systemImage: "folder.badge.plus")
                    }
                    Button {
                        engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
                    } label: {
                        Label("Import Executable (.exe / .app)...", systemImage: "gamecontroller")
                    }
                    Divider()
                    Button {
                        engine.launchWindowsSteamSandbox()
                    } label: {
                        Label("Launch Windows Steam Sandbox...", systemImage: "shippingbox.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    engine.scanAllLaunchers()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(Angle(degrees: engine.isScanning ? 360 : 0))
                        .animation(engine.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)
                }
                .disabled(engine.isScanning)
                .help("Rescan installed games across Steam, GOG, Epic, and Mac apps")
            }
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
                GameArtworkView(game: game, cornerRadius: 12)
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
                .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
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
            } else if let headerURL = game.steamHeaderImageURL, let url = URL(string: headerURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        proceduralArtwork
                    @unknown default:
                        proceduralArtwork
                    }
                }
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
