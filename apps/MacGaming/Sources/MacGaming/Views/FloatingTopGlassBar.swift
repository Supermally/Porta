import SwiftUI

public struct FloatingTopGlassBar: View {
    @ObservedObject var engine: EngineService
    @Binding var isCollapsed: Bool

    @FocusState private var isSearchFocused: Bool

    public init(engine: EngineService, isCollapsed: Binding<Bool>) {
        self.engine = engine
        self._isCollapsed = isCollapsed
    }

    public var body: some View {
        HStack(spacing: 10) {
            if isCollapsed {
                collapsedBar
            } else {
                expandedBar
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCollapsed)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: engine.searchText.isEmpty)
    }

    // MARK: - Expanded Top Bar
    private var expandedBar: some View {
        HStack(spacing: 12) {
            // 1. Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Search games…", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .frame(minWidth: 120, idealWidth: 160)

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
                        .foregroundColor(engine.libraryViewMode == .grid ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { engine.libraryViewMode = .list }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: engine.libraryViewMode == .list ? .bold : .regular))
                        .padding(5)
                        .foregroundColor(engine.libraryViewMode == .list ? .accentColor : .secondary)
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
                    .foregroundColor(.accentColor)
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
            Button(action: { isCollapsed = true }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("Collapse control bar")
        }
    }

    // MARK: - Collapsed Top Bar
    private var collapsedBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                isCollapsed = false
                isSearchFocused = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                    if !engine.searchText.isEmpty {
                        Text(engine.searchText)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    } else {
                        Text("Search")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 14)
                .opacity(0.3)

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
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .menuStyle(.borderlessButton)

            Button(action: { isCollapsed = false }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Expand control bar")
        }
        .padding(.horizontal, 4)
    }
}
