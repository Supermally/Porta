import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: EngineService
    @State private var wineVersion: String = "Apple D3DMetal + Wine-CX-23.7 (Default)"
    @State private var enableEsync: Bool = true
    @State private var enableFsync: Bool = true
    @State private var shaderCacheEnabled: Bool = true
    @State private var enableMetalHud: Bool = false
    @State private var testVolume: Double = 0.75

    // Developer Visual Debug Mode & Morph Test State
    @State private var isDebugModeEnabled: Bool = false
    @State private var isTestMorphExpanded: Bool = false
    @Namespace private var testMorphNamespace

    public init(engine: EngineService) {
        self._engine = ObservedObject(wrappedValue: engine)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Configure Apple Liquid Glass optics, graphics runtimes, and application permissions.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 4)

                // 1. Apple Liquid Glass Configuration Card
                settingsCard(title: "Liquid Glass Material & Optics", icon: "sparkles") {
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle("Enable Apple Liquid Glass", isOn: $engine.glassConfig.enabled)
                            .toggleStyle(.switch)

                        if engine.glassConfig.enabled {
                            Divider().opacity(0.3)

                            HStack {
                                Text("Glass Appearance")
                                    .font(.system(size: 13))
                                Spacer()
                                Picker("", selection: $engine.glassConfig.variant) {
                                    ForEach(GlassVariant.allCases) { variant in
                                        Text(variant.rawValue).tag(variant)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 240)
                            }

                            HStack {
                                Text("Interactive Response")
                                    .font(.system(size: 13))
                                Spacer()
                                Picker("", selection: $engine.glassConfig.interactionResponse) {
                                    ForEach(InteractionResponseLevel.allCases) { level in
                                        Text(level.rawValue).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 240)
                            }

                            HStack {
                                Text("Fluid Morphing Physics")
                                    .font(.system(size: 13))
                                Spacer()
                                Picker("", selection: $engine.glassConfig.morphingMode) {
                                    ForEach(MorphingMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 240)
                            }

                            Divider().opacity(0.3)

                            // Interactive Liquid Glass Lens Test Playground
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Interactive Liquid Glass Lens Playground (Press & Drag to Activate Lens)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                ZStack {
                                    // Underflow Color Bars to Test Lens Refraction
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
                                    }
                                    .frame(height: 72)
                                    .opacity(0.85)

                                    // Floating Lens Controls Over Underflow Bars
                                    HStack(spacing: 16) {
                                        PlayButton(state: .idle, onPlay: {})

                                        GlassEffectContainer(spacing: 8) {
                                            Button {} label: {
                                                Label("Action", systemImage: "sparkles")
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)

                                            Divider()
                                                .frame(height: 14)
                                                .opacity(0.3)

                                            Button {} label: {
                                                Image(systemName: "gearshape")
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                        }

                                        CompatibilityBadgeView(.native)
                                    }
                                    .padding(.horizontal, 14)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                // Live Slider Lens Test (Direct Drag ONLY)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Slider Lens (Direct Drag Triggered)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(testVolume * 100))%")
                                            .font(.caption.monospaced())
                                            .foregroundColor(.secondary)
                                    }
                                    MGGlassSlider(
                                        value: $testVolume,
                                        in: 0.0...1.0,
                                        step: 0.01,
                                        gradientColors: [Color.blue, Color.cyan]
                                    )
                                }
                                .padding(.top, 4)
                            }

                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        engine.resetGlassDefaults()
                                    }
                                } label: {
                                    Label("Reset Glass to Apple Defaults", systemImage: "arrow.counterclockwise")
                                }
                                .buttonStyle(.glass)
                            }
                        }
                    }
                }

                // 2. Developer Visual Debug Mode & Morphing Test
                settingsCard(title: "Developer Liquid Glass Diagnostics & Morph Test", icon: "wrench.and.screwdriver") {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Enable Visual Debug Diagnostic Mode", isOn: $isDebugModeEnabled)
                            .toggleStyle(.switch)

                        if isDebugModeEnabled {
                            Divider().opacity(0.3)

                            // Diagnostic State Badges
                            HStack(spacing: 12) {
                                diagnosticBadge(title: "GLASS", value: "NATIVE", color: .blue)
                                diagnosticBadge(title: "LENS TRIGGER", value: "PRESS / DRAG ONLY", color: .green)
                                diagnosticBadge(title: "MORPH", value: isTestMorphExpanded ? "EXPANDED" : "COLLAPSED", color: .purple)
                            }

                            Divider().opacity(0.3)

                            // Extreme Geometry Morph Test (Circle <-> Large Capsule)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Native GlassEffectContainer Morph Test (Circle ⟷ Large Capsule)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                GlassEffectContainer(spacing: 40) {
                                    if isTestMorphExpanded {
                                        HStack(spacing: 14) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 15, weight: .semibold))
                                            Text("Search library, filters & recents…")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Button {
                                                withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) {
                                                    isTestMorphExpanded = false
                                                }
                                            } label: {
                                                Image(systemName: "chevron.up")
                                            }
                                            .buttonStyle(.glass)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .frame(height: 52)
                                        .glassEffect(.regular.interactive(), in: Capsule())
                                        .glassEffectID("morphTestElement", in: testMorphNamespace)
                                    } else {
                                        Button {
                                            withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) {
                                                isTestMorphExpanded = true
                                            }
                                        } label: {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 16, weight: .bold))
                                                .frame(width: 48, height: 48)
                                        }
                                        .buttonStyle(.glass)
                                        .clipShape(Circle())
                                        .glassEffect(.regular.interactive(), in: Circle())
                                        .glassEffectID("morphTestElement", in: testMorphNamespace)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                // 3. Graphics & Compatibility Runtimes Card
                settingsCard(title: "Graphics & Compatibility Runtime", icon: "cpu") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Wine Runner")
                                .font(.system(size: 13))
                            Spacer()
                            Picker("", selection: $wineVersion) {
                                Text("MacGaming Managed Wine Staging (Default)").tag("MacGaming Managed Wine Staging (Default)")
                                Text("Whisky / CrossOver Wine-GE-Proton").tag("Whisky / CrossOver Wine-GE-Proton")
                                Text("Wine-Staging 9.0 (Custom)").tag("Wine-Staging 9.0 (Custom)")
                            }
                            .frame(width: 320)
                        }

                        Divider().opacity(0.3)

                        Toggle("Eventfd Synchronization (Esync)", isOn: $enableEsync)
                            .toggleStyle(.switch)
                        Toggle("Futex Synchronization (Fsync)", isOn: $enableFsync)
                            .toggleStyle(.switch)
                        Toggle("Persist Shader Pre-Caching on Disk", isOn: $shaderCacheEnabled)
                            .toggleStyle(.switch)
                        Toggle("Metal Performance HUD Overlay", isOn: $enableMetalHud)
                            .toggleStyle(.switch)
                    }
                }

                // 4. Managed Components & Runtimes Card
                settingsCard(title: "Installed Components & Runtimes", icon: "shippingbox.fill") {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(DependencyManager.shared.dependencies) { dep in
                            HStack {
                                Label(dep.name, systemImage: dep.category.icon)
                                    .font(.system(size: 13))
                                Spacer()
                                switch dep.status {
                                case .installed(let ver):
                                    Text("v\(ver) • Installed")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                case .notInstalled:
                                    Text("Not Installed")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                case .outdated(_, let avail):
                                    Text("Update Available (v\(avail))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                case .downloading, .installing, .verifying:
                                    ProgressView()
                                        .controlSize(.small)
                                case .failed:
                                    Text("Error")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                            if dep.id != DependencyManager.shared.dependencies.last?.id {
                                Divider().opacity(0.2)
                            }
                        }

                        Divider().opacity(0.3)

                        HStack {
                            Spacer()
                            Button {
                                DependencyManager.shared.inspectAllDependencies()
                            } label: {
                                Label("Re-verify Installed Components", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }

                // 5. Application Permissions & Security Card
                settingsCard(title: "Application Permissions & Security", icon: "lock.shield.fill") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Remembered File & Folder Access", systemImage: "folder.badge.gearshape")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(PermissionManager.shared.savedBookmarks.count) Saved Bookmarks")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Divider().opacity(0.2)

                        HStack {
                            Label("Accessibility / Gamepad Hooks", systemImage: "hand.tap.fill")
                                .font(.system(size: 13))
                            Spacer()
                            HStack(spacing: 8) {
                                Text(PermissionManager.shared.accessibilityStatus.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PermissionManager.shared.accessibilityStatus == .authorized ? .green : .orange)

                                if PermissionManager.shared.accessibilityStatus != .authorized {
                                    Button("Grant Access") {
                                        PermissionManager.shared.requestAccessibilityPermission()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }

                        Divider().opacity(0.2)

                        HStack {
                            Label("Game Controller / Input Monitoring", systemImage: "gamecontroller.fill")
                                .font(.system(size: 13))
                            Spacer()
                            Button("Open Privacy Settings") {
                                PermissionManager.shared.openSystemSettings(for: "inputMonitoring")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if !PermissionManager.shared.savedBookmarks.isEmpty {
                            Divider().opacity(0.3)
                            Button(role: .destructive) {
                                PermissionManager.shared.clearAllSavedBookmarks()
                            } label: {
                                Label("Clear Saved File Access Permissions", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 6. Hardware Specifications Card
                settingsCard(title: "System & Hardware", icon: "macmini.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Apple Silicon Chip")
                                .font(.system(size: 13))
                            Spacer()
                            Text(engine.hardware.chipName)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Divider().opacity(0.2)
                        HStack {
                            Text("Unified Memory")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(engine.hardware.memoryGB) GB")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Divider().opacity(0.2)
                        HStack {
                            Text("macOS System Version")
                                .font(.system(size: 13))
                            Spacer()
                            Text(engine.hardware.osVersion)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .frame(maxWidth: 820)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Reusable Apple Settings Card Container
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.70))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func diagnosticBadge(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(Capsule().strokeBorder(color.opacity(0.30), lineWidth: 0.8))
        )
    }
}
