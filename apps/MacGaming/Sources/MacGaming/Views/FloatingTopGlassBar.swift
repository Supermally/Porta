import SwiftUI

public struct FloatingTopGlassBar: View {
    @ObservedObject var engine: EngineService
    @Binding var isCollapsed: Bool

    @FocusState private var isSearchFocused: Bool
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.liquidGlassConfiguration) private var config

    public init(engine: EngineService, isCollapsed: Binding<Bool>) {
        self.engine = engine
        self._isCollapsed = isCollapsed
    }

    public var body: some View {
        GlassEffectContainer(spacing: 24) {
            if isCollapsed {
                collapsedBubbleView
                    .glassEffect(.regular.interactive(), in: Circle())
                    .glassEffectID("searchBarControl", in: glassNamespace)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.85).combined(with: .opacity))
            } else {
                expandedGlassBarView
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .glassEffectID("searchBarControl", in: glassNamespace)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.90).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.74), value: isCollapsed)
    }

    // MARK: - 1. Collapsed State: Liquid Glass Search & Action Bubble
    private var collapsedBubbleView: some View {
        Button(action: {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.74)) {
                isCollapsed = false
                isSearchFocused = true
            }
        }) {
            ZStack {
                HStack(spacing: 3) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(engine.searchText.isEmpty ? .primary : (config.accentTint ?? .accentColor))

                    if !engine.searchText.isEmpty {
                        Circle()
                            .fill(config.accentTint ?? Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
        .help("Open top control bar (⌘F)")
        .keyboardShortcut("f", modifiers: .command)
    }

    // MARK: - 2. Expanded State: Full Functional Top Bar
    private var expandedGlassBarView: some View {
        HStack(spacing: 12) {
            // 1. Search Field
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Search library…", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .frame(minWidth: 120, idealWidth: 160)
                    .onSubmit {
                        if engine.searchText.isEmpty {
                            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.74)) {
                                isCollapsed = true
                            }
                        }
                    }

                if !engine.searchText.isEmpty {
                    Button(action: { engine.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.05))
            )

            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // 2. Launchers & Storefronts Menu Tab
            Menu {
                Section("Filter Storefront") {
                    ForEach(StorefrontFilter.allCases, id: \.self) { filter in
                        Button {
                            engine.selectedStorefront = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if engine.selectedStorefront == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Launch Storefronts") {
                    Button {
                        engine.launchSteam()
                    } label: {
                        Label("Open Steam (Wine)", systemImage: "play.circle")
                    }

                    Button {
                        engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
                    } label: {
                        Label("Launch External Client...", systemImage: "arrow.up.forward.app")
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 12))
                    Text(engine.selectedStorefront == .all ? "Launchers" : engine.selectedStorefront.rawValue)
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundColor(engine.selectedStorefront != .all ? (config.accentTint ?? .blue) : .primary)
            }
            .menuStyle(.borderlessButton)

            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // 3. View Mode & Layout Tab
            Menu {
                Section("Layout") {
                    Button {
                        engine.libraryViewMode = .grid
                    } label: {
                        HStack {
                            Label("Grid View", systemImage: "square.grid.2x2")
                            if engine.libraryViewMode == .grid { Image(systemName: "checkmark") }
                        }
                    }

                    Button {
                        engine.libraryViewMode = .list
                    } label: {
                        HStack {
                            Label("List View", systemImage: "list.bullet")
                            if engine.libraryViewMode == .list { Image(systemName: "checkmark") }
                        }
                    }
                }

                Section("Compatibility Filter") {
                    Button {
                        engine.selectedFilter = nil
                    } label: {
                        HStack {
                            Text("All Tiers")
                            if engine.selectedFilter == nil { Image(systemName: "checkmark") }
                        }
                    }

                    ForEach(CompatibilityBadge.allCases, id: \.self) { badge in
                        Button {
                            engine.selectedFilter = badge
                        } label: {
                            HStack {
                                Text(badge.rawValue)
                                if engine.selectedFilter == badge { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: engine.libraryViewMode == .grid ? "square.grid.2x2" : "list.bullet")
                        .font(.system(size: 12))
                    Text("View")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)

            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // 4. Quick Settings & Graphics Tweaks Menu Tab
            Menu {
                Section("Graphics Translation Pipeline") {
                    Button {
                        engine.isDeveloperModeEnabled.toggle()
                    } label: {
                        HStack {
                            Label("Developer Mode", systemImage: "wrench.and.screwdriver")
                            if engine.isDeveloperModeEnabled { Image(systemName: "checkmark") }
                        }
                    }

                    Button {
                        engine.scanAllLaunchers()
                    } label: {
                        Label("Rescan Environments & Games", systemImage: "arrow.clockwise")
                    }
                }

                Section("Navigation") {
                    Button {
                        engine.activeTab = .settings
                    } label: {
                        Label("Open Full Settings…", systemImage: "gearshape")
                    }
                    Button {
                        engine.activeTab = .debugLab
                    } label: {
                        Label("Open Graphics Debug Lab…", systemImage: "cpu")
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                    Text("Settings")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)

            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // 5. Add / Import Action Menu
            Menu {
                Button {
                    engine.openNativeFilePicker(chooseFolder: true)
                } label: {
                    Label("Import Game Folder…", systemImage: "folder.badge.plus")
                }
                Button {
                    engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
                } label: {
                    Label("Import Executable (.exe / .app)…", systemImage: "gamecontroller")
                }
                Button {
                    engine.openNativeFilePicker(isUniversalApp: true, chooseFolder: false)
                } label: {
                    Label("Import Universal Software…", systemImage: "cube.fill")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(config.accentTint ?? .blue)
            }
            .menuStyle(.borderlessButton)

            // 6. Collapse Bar Button
            Button(action: {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.74)) {
                    isSearchFocused = false
                    isCollapsed = true
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .help("Collapse to bubble (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(height: 44)
    }
}
