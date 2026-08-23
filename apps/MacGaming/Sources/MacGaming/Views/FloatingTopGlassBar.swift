import SwiftUI

public enum SearchPresentationState: Equatable, Sendable {
    case collapsed
    case expanding
    case expanded
    case collapsing
}

public struct FloatingTopGlassBar: View {
    @ObservedObject var engine: EngineService
    @Binding var isCollapsed: Bool

    @FocusState private var isSearchFocused: Bool
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovered: Bool = false
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.liquidGlassConfiguration) private var config

    public init(engine: EngineService, isCollapsed: Binding<Bool>) {
        self.engine = engine
        self._isCollapsed = isCollapsed
    }

    public var body: some View {
        ZStack {
            if isCollapsed {
                collapsedBubbleView
                    .glassEffectID("searchBar", in: glassNamespace)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.88).combined(with: .opacity))
            } else {
                expandedGlassBarView
                    .glassEffectID("searchBar", in: glassNamespace)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.74), value: isCollapsed)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                hoverLocation = location
                isHovered = true
            case .ended:
                isHovered = false
            }
        }
    }

    // MARK: - 1. Collapsed State: Liquid Glass Search Bubble
    private var collapsedBubbleView: some View {
        Button(action: {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.74)) {
                isCollapsed = false
                isSearchFocused = true
            }
        }) {
            ZStack {
                // Background Liquid Glass Orb
                Circle()
                    .fill(Color.white.opacity(config.variant == .clear ? 0.08 : 0.14))
                    .background(config.variant == .clear ? .ultraThinMaterial : .regularMaterial, in: Circle())
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.14), radius: 10, y: 4)

                // Reactive Specular Lens Highlight (Tracks pointer location)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.50),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            center: isHovered ? UnitPoint(x: hoverLocation.x / 44, y: hoverLocation.y / 44) : .topLeading,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                // 3D Glass Bevel Rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.80), location: 0.0),
                                .init(color: Color.white.opacity(0.18), location: 0.5),
                                .init(color: Color.white.opacity(0.45), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                    .frame(width: 44, height: 44)

                // Magnifying Glass Search Icon
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
        }
        .buttonStyle(.plain)
        .help("Search games (⌘F)")
        .keyboardShortcut("f", modifiers: .command)
    }

    // MARK: - 2. Expanded State: Organic Liquid Glass Control Capsule
    private var expandedGlassBarView: some View {
        HStack(spacing: 12) {
            // 1. Search Field
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Search games…", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .frame(minWidth: 140, idealWidth: 180)
                    .onSubmit {
                        if engine.searchText.isEmpty {
                            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.74)) {
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

            // 2. View Mode (Grid / List)
            HStack(spacing: 2) {
                Button(action: { engine.libraryViewMode = .grid }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 12, weight: engine.libraryViewMode == .grid ? .bold : .regular))
                        .padding(5)
                        .foregroundColor(engine.libraryViewMode == .grid ? (config.accentTint ?? .accentColor) : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { engine.libraryViewMode = .list }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: engine.libraryViewMode == .list ? .bold : .regular))
                        .padding(5)
                        .foregroundColor(engine.libraryViewMode == .list ? (config.accentTint ?? .accentColor) : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.04))
            )

            // 3. Storefront Filter Menu
            Menu {
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
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12))
                    Text(engine.selectedStorefront == .all ? "Filter" : engine.selectedStorefront.rawValue)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)

            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // 4. Import Executable Menu
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
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(config.accentTint ?? .accentColor)
            }
            .menuStyle(.borderlessButton)

            // 5. Rescan Library
            Button(action: { engine.scanAllLaunchers() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .rotationEffect(Angle(degrees: engine.isScanning ? 360 : 0))
                    .animation(engine.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)
            }
            .buttonStyle(.plain)
            .disabled(engine.isScanning)

            // 6. Collapse Bar Button
            Button(action: {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.74)) {
                    isSearchFocused = false
                    isCollapsed = true
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .help("Collapse to bubble (Esc)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // 1. Crystal-clear transmission substrate
                Capsule()
                    .fill(Color.white.opacity(config.variant == .clear ? 0.08 : 0.14))
                    .background(config.variant == .clear ? .ultraThinMaterial : .regularMaterial, in: Capsule())

                // 2. Cursor-Reactive Specular Rim
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            center: isHovered ? UnitPoint(x: hoverLocation.x / 400, y: hoverLocation.y / 40) : .topLeading,
                            startRadius: 5,
                            endRadius: 180
                        )
                    )
                    .clipShape(Capsule())

                // 3. 3D Specular Bevel Rim
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.80), location: 0.0),
                                .init(color: Color.white.opacity(0.18), location: 0.5),
                                .init(color: Color.white.opacity(0.45), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
            .shadow(color: Color.black.opacity(0.14), radius: 12, y: 4)
        )
    }
}
