import SwiftUI
import AppKit

public struct LibraryView: View {
    @ObservedObject var engine: EngineService

    private let gridColumns = [
        GridItem(.adaptive(minimum: 155, maximum: 195), spacing: 20)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Floating Liquid Glass Navigation Toolbar
            HStack(spacing: 12) {
                // Floating Glass Search Capsule
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13, weight: .medium))
                    TextField("Search library...", text: $engine.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                    if !engine.searchText.isEmpty {
                        Button(action: { engine.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                .frame(minWidth: 170)

                Spacer(minLength: 8)

                // Floating Glass View Mode Switcher
                HStack(spacing: 0) {
                    Picker("", selection: $engine.libraryViewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Image(systemName: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 72)
                }
                .padding(3)
                .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Floating Glass Import Menu
                Menu {
                    Button(action: { engine.openNativeFilePicker(chooseFolder: true) }) {
                        Label("Import Game Folder...", systemImage: "folder.badge.plus")
                    }
                    Button(action: { engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false) }) {
                        Label("Import Executable (.exe / .app)...", systemImage: "gamecontroller")
                    }
                    Divider()
                    Button(action: { engine.launchWindowsSteamSandbox() }) {
                        Label("Launch Windows Steam Sandbox...", systemImage: "shippingbox.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .padding(8)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Floating Glass Rescan Button
                Button(action: { engine.scanAllLaunchers() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(Angle(degrees: engine.isScanning ? 360 : 0))
                        .animation(engine.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)
                        .padding(8)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                }
                .buttonStyle(.plain)
                .disabled(engine.isScanning)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()
                .opacity(0.15)

            // Library Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Recently Played Shelf
                    if engine.searchText.isEmpty && engine.selectedFilter == nil && engine.selectedStorefront == .all {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 15, weight: .bold))
                                Text("Recently Played")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(engine.games.prefix(4))) { game in
                                        RecentGameGlassCard(game: game, engine: engine, isSelected: engine.selectedGame?.id == game.id) {
                                            engine.selectedGame = game
                                        } onPlay: {
                                            engine.launchGame(game)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // All Games Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(engine.selectedStorefront == .all ? "All Games" : engine.selectedStorefront.rawValue)
                                .font(.system(size: 17, weight: .bold))
                            Spacer()
                            Text("\(engine.filteredGames.count) titles")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        if engine.libraryViewMode == .grid {
                            // Floating Liquid Glass Posters Grid
                            LazyVGrid(columns: gridColumns, spacing: 20) {
                                ForEach(engine.filteredGames) { game in
                                    GameGridGlassCard(game: game, engine: engine, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    } onPlay: {
                                        engine.launchGame(game)
                                    }
                                }
                            }
                        } else {
                            // Floating Liquid Glass List Rows
                            VStack(spacing: 8) {
                                ForEach(engine.filteredGames) { game in
                                    GameListGlassRow(game: game, engine: engine, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    } onPlay: {
                                        engine.launchGame(game)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .onHover { _ in NSCursor.arrow.set() }
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
                        colors: [
                            Color.accentColor.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 8) {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                        Text(game.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .lineLimit(2)
                    }
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
                colors: [
                    game.bannerColor.opacity(0.85),
                    game.bannerColor.opacity(0.40),
                    Color.black.opacity(0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: game.isNative ? "apple.logo" : (game.isUnityGame ? "cube.fill" : "gamecontroller.fill"))
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                Text(game.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Recently Played Responsive Glass Card
struct RecentGameGlassCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    GameArtworkView(game: game, cornerRadius: 14)
                        .frame(width: 180, height: 112)

                    // Floating Glass Status Badge
                    HStack {
                        Text(game.badge.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(width: 180, alignment: .leading)
            }
            .padding(6)
            .liquidGlassBubble(cornerRadius: 18, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isHovered ? Color.white.opacity(0.4) : Color.clear), lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.35) : (isHovered ? Color.black.opacity(0.18) : Color.clear), radius: isHovered ? 10 : 0, y: 4)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Responsive Grid Glass Poster Card
struct GameGridGlassCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    GameArtworkView(game: game, cornerRadius: 14)
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()

                    // Floating Glass Compatibility Pill
                    Text(game.badge.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                        .foregroundColor(.white)
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 2)
            }
            .padding(6)
            .liquidGlassBubble(cornerRadius: 18, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isHovered ? Color.white.opacity(0.4) : Color.clear), lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.35) : (isHovered ? Color.black.opacity(0.18) : Color.clear), radius: isHovered ? 10 : 0, y: 4)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Responsive List Glass Row
struct GameListGlassRow: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Mini Artwork Bubble
                GameArtworkView(game: game, cornerRadius: 8)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(game.developerName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Storefront
                Text(game.storefront)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)

                // Compatibility Glass Pill
                Text(game.badge.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                    .foregroundColor(game.badge.color)
                    .frame(width: 85)

                // Target FPS
                Text("\(game.targetFps) FPS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)

                // Quick Play Action Button
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .padding(8)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .liquidGlassBubble(cornerRadius: 16, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isHovered ? Color.white.opacity(0.3) : Color.clear), lineWidth: 1.5)
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
