import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: EngineService
    @State private var wineVersion: String = "Apple D3DMetal + Wine-CX-23.7 (Default)"
    @State private var enableEsync: Bool = true
    @State private var enableFsync: Bool = true
    @State private var shaderCacheEnabled: Bool = true
    @State private var enableMetalHud: Bool = false
    @State private var testVolume: Double = 0.75
    @State private var testFpsTarget: Double = 120.0

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
                        MGGlassToggle("Enable Apple Liquid Glass", isOn: $engine.glassConfig.enabled)

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
                                Text("Interactive Liquid Glass Lens Playground")
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

                                // Live Slider Lens Test
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Lens Slider Test (Drag to observe momentum stretch)")
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

                // 2. Graphics & Compatibility Runtimes Card
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

                        MGGlassToggle("Eventfd Synchronization (Esync)", isOn: $enableEsync)
                        MGGlassToggle("Futex Synchronization (Fsync)", isOn: $enableFsync)
                        MGGlassToggle("Persist Shader Pre-Caching on Disk", isOn: $shaderCacheEnabled)
                        MGGlassToggle("Metal Performance HUD Overlay", isOn: $enableMetalHud)
                    }
                }

                // 3. Managed Components & Runtimes Card
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

                // 4. Application Permissions & Security Card
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

                // 5. Hardware Specifications Card
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
}
