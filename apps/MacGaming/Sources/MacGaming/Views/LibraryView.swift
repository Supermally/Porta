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
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
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
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
                }
                .buttonStyle(.plain)
                .disabled(engine.isScanning)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()
                .opacity(0.2)

            // Library Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Recently Played Shelf (Liquid Glass Floating Pods)
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
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
                    .background(Color.black.opacity(0.15))
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
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(game.bannerColor.gradient)
            VStack(spacing: 8) {
                Image(systemName: game.isNative ? "apple.logo" : (game.isUnityGame ? "cube.fill" : "gamecontroller.fill"))
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.9))
                Text(game.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Recently Played Glass Bubble Card
struct RecentGameGlassCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    GameArtworkView(game: game, cornerRadius: 18)
                        .frame(width: 185, height: 118)

                    // Floating Glass Badge
                    HStack {
                        Text(game.badge.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(10)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                .frame(width: 185, alignment: .leading)
            }
            .padding(8)
            .liquidGlassBubble(cornerRadius: 22, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Glass Poster Card
struct GameGridGlassCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    GameArtworkView(game: game, cornerRadius: 18)
                        .aspectRatio(2/3, contentMode: .fit)

                    // Floating Glass Compatibility Pill
                    Text(game.badge.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                        .foregroundColor(.white)
                        .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(10)
            .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Glass Row
struct GameListGlassRow: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

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
                        .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .liquidGlassBubble(cornerRadius: 16, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, isInteractive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
