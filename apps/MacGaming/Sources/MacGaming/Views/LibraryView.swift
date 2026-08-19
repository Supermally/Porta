import SwiftUI
import AppKit

public struct LibraryView: View {
    @ObservedObject var engine: EngineService

    private let gridColumns = [
        GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 16)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Liquid Glass Top Navigation & Controls Toolbar
            HStack(spacing: 12) {
                // Search Field (Non-crammed, flexible layout)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    TextField("Search library...", text: $engine.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !engine.searchText.isEmpty {
                        Button(action: { engine.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(8)
                .frame(minWidth: 160)

                Spacer(minLength: 8)

                // View Mode Toggle (Grid vs List)
                Picker("View Mode", selection: $engine.libraryViewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 76)

                // Import Menu
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
                        .font(.system(size: 12, weight: .semibold))
                        .padding(6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Rescan Library Button
                Button(action: { engine.scanAllLaunchers() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(Angle(degrees: engine.isScanning ? 360 : 0))
                        .animation(engine.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)
                        .padding(6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(engine.isScanning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 0, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

            Divider()

            // Library Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recently Played Shelf (Apple Music Style)
                    if engine.searchText.isEmpty && engine.selectedFilter == nil && engine.selectedStorefront == .all {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Played")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(Array(engine.games.prefix(4))) { game in
                                        RecentGamePosterCard(game: game, engine: engine, isSelected: engine.selectedGame?.id == game.id) {
                                            engine.selectedGame = game
                                        } onPlay: {
                                            engine.launchGame(game)
                                        }
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                    }

                    // All Games Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(engine.selectedStorefront == .all ? "All Games" : engine.selectedStorefront.rawValue)
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("\(engine.filteredGames.count) titles")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        if engine.libraryViewMode == .grid {
                            // Grid Mode (Posters)
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(engine.filteredGames) { game in
                                    GameGridPosterCard(game: game, engine: engine, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    } onPlay: {
                                        engine.launchGame(game)
                                    }
                                }
                            }
                        } else {
                            // List Mode (Apple Music Rows)
                            VStack(spacing: 4) {
                                ForEach(engine.filteredGames) { game in
                                    GameListRow(game: game, isSelected: engine.selectedGame?.id == game.id) {
                                        engine.selectedGame = game
                                    } onPlay: {
                                        engine.launchGame(game)
                                    }
                                }
                            }
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onHover { _ in NSCursor.arrow.set() }
    }
}

// MARK: - Game Image Loader Component (Local Steam cache / Native .app bundle / Fallback)
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
                    .padding(14)
                    .background(Color.black.opacity(0.1))
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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var proceduralArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(game.bannerColor.gradient)
            VStack(spacing: 6) {
                Image(systemName: game.isNative ? "apple.logo" : (game.isUnityGame ? "cube.fill" : "gamecontroller.fill"))
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.9))
                Text(game.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Recently Played Poster Card
struct RecentGamePosterCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    GameArtworkView(game: game, cornerRadius: 10)
                        .frame(width: 175, height: 110)

                    // Glass Bottom Title Tag
                    HStack {
                        Text(game.badge.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .liquidGlass(cornerRadius: 4, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(width: 175, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
    }
}

// MARK: - Grid Poster Card
struct GameGridPosterCard: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    GameArtworkView(game: game, cornerRadius: 10)
                        .aspectRatio(2/3, contentMode: .fit)

                    // Compatibility Badge Pill
                    Text(game.badge.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .liquidGlass(cornerRadius: 4, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                        .foregroundColor(.white)
                        .padding(6)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2.5 : 1)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(game.storefront)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
    }
}

// MARK: - List Row (Apple Music Style)
struct GameListRow: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Mini Artwork
                GameArtworkView(game: game, cornerRadius: 6)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
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
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)

                // Compatibility Pill
                Text(game.badge.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(game.badge.color.opacity(0.15))
                    .foregroundColor(game.badge.color)
                    .cornerRadius(5)
                    .frame(width: 80)

                // Target FPS / Preset
                Text("\(game.targetFps) FPS")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)

                // Quick Play Button
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .padding(6)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
    }
}
