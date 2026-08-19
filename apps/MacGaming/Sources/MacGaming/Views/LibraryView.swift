import SwiftUI

public struct LibraryView: View {
    @ObservedObject var engine: EngineService

    public var body: some View {
        VStack(spacing: 0) {
            // Refined Liquid Glass Header Bar
            VStack(spacing: 10) {
                // Top Row: Storefront Dropdown & Action Buttons (Never cut off)
                HStack(spacing: 8) {
                    // Storefront Selector Menu
                    Menu {
                        ForEach(StorefrontFilter.allCases) { sf in
                            Button(action: { engine.selectedStorefront = sf }) {
                                Label(sf.rawValue, systemImage: sf.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: engine.selectedStorefront.icon)
                                .foregroundColor(.accentColor)
                                .font(.system(size: 11, weight: .semibold))
                            Text(engine.selectedStorefront.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Spacer(minLength: 4)

                    // Import Button with Menu
                    Menu {
                        Button(action: { engine.openNativeFilePicker(chooseFolder: true) }) {
                            Label("Import Game Folder (Auto-runs All Files)...", systemImage: "folder.badge.plus")
                        }
                        Button(action: { engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false) }) {
                            Label("Import Game (.exe / .app)...", systemImage: "gamecontroller")
                        }
                        Button(action: { engine.openNativeFilePicker(isUniversalApp: true, chooseFolder: false) }) {
                            Label("Import Windows App...", systemImage: "macwindow.badge.plus")
                        }
                        Divider()
                        Button(action: { engine.launchWindowsSteamSandbox() }) {
                            Label("Launch Windows Steam Sandbox (Path ③)...", systemImage: "shippingbox.fill")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Import")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Import external Windows executable or macOS app bundle")

                    // Rescan Library Button
                    Button(action: { engine.scanAllLaunchers() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(Angle(degrees: engine.isScanning ? 360 : 0))
                            .animation(engine.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)
                            .padding(6)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .disabled(engine.isScanning)
                    .help("Rescan installed Steam, GOG, Epic, itch, Ubisoft, EA, and Battle.net libraries")
                }

                // Second Row: Horizontally Scrollable Status Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Button(action: { engine.selectedFilter = nil }) {
                            Text("All (\(engine.games.count))")
                                .font(.system(size: 11, weight: engine.selectedFilter == nil ? .bold : .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(engine.selectedFilter == nil ? Color.accentColor : Color.primary.opacity(0.06))
                                .foregroundColor(engine.selectedFilter == nil ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        ForEach(CompatibilityBadge.allCases) { badge in
                            let count = engine.games.filter { $0.badge == badge }.count
                            if count > 0 || engine.selectedFilter == badge {
                                Button(action: {
                                    if engine.selectedFilter == badge {
                                        engine.selectedFilter = nil
                                    } else {
                                        engine.selectedFilter = badge
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: badge.iconName)
                                            .font(.system(size: 9, weight: .bold))
                                        Text("\(badge.rawValue) (\(count))")
                                            .font(.system(size: 11, weight: engine.selectedFilter == badge ? .bold : .medium))
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(engine.selectedFilter == badge ? badge.color.opacity(0.2) : Color.primary.opacity(0.06))
                                    .foregroundColor(engine.selectedFilter == badge ? badge.color : .primary)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider()

            // Game & Software Library List
            List(selection: $engine.selectedGame) {
                ForEach(engine.filteredGames) { game in
                    HStack(spacing: 12) {
                        Image(systemName: game.badge.iconName)
                            .foregroundColor(game.badge.color)
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(game.title)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)

                            HStack(spacing: 5) {
                                Text(game.storefront)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                Text(game.isNative ? "Native macOS" : (game.isUniversalApp ? "Windows App" : "DirectX / Metal"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        StatusBadgeView(badge: game.badge)
                    }
                    .padding(.vertical, 4)
                    .tag(game)
                }
            }
            .listStyle(.sidebar)
        }
    }
}

public struct StatusBadgeView: View {
    let badge: CompatibilityBadge

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badge.iconName)
                .font(.system(size: 9, weight: .bold))
            Text(badge.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(badge.color.opacity(0.14))
        .foregroundColor(badge.color)
        .cornerRadius(5)
    }
}
