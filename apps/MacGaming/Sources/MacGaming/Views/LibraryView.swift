import SwiftUI

public struct LibraryView: View {
    @ObservedObject var engine: EngineService

    private let gridColumns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Liquid Glass Top Navigation & Controls Toolbar
            HStack(spacing: 10) {
                // Search Field
                HStack(spacing: 6) {
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
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(8)

                Spacer()

                // View Mode Toggle (Grid vs List)
                Picker("View Mode", selection: $engine.libraryViewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 72)

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
            .background(.ultraThinMaterial)

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
                                        RecentGamePosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
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
                                    GameGridPosterCard(game: game, isSelected: engine.selectedGame?.id == game.id) {
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
    }
}

// MARK: - Recently Played Poster Card
struct RecentGamePosterCard: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(game.bannerColor.gradient.opacity(0.85))
                        .frame(width: 170, height: 110)
                        .overlay(
                            VStack {
                                Image(systemName: game.isNative ? "apple.logo" : (game.isUnityGame ? "cube.fill" : "gamecontroller.fill"))
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )

                    // Glass Bottom Title Tag
                    HStack {
                        Text(game.badge.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .cornerRadius(4)
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
                .frame(width: 170, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Poster Card
struct GameGridPosterCard: View {
    let game: GameItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(game.bannerColor.gradient.opacity(0.8))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.85))
                                Text(game.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                                    .lineLimit(2)
                            }
                        )

                    // Compatibility Badge Pill
                    Text(game.badge.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(4)
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(game.bannerColor.gradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )

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
    }
}
