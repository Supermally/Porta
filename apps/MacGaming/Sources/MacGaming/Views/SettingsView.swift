import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: EngineService
    @State private var wineVersion: String = "Apple D3DMetal + Wine-CX-23.7 (Default)"
    @State private var enableEsync: Bool = true
    @State private var enableFsync: Bool = true
    @State private var shaderCacheEnabled: Bool = true
    @State private var enableMetalHud: Bool = false

    public init(engine: EngineService) {
        self._engine = ObservedObject(wrappedValue: engine)
    }

    public var body: some View {
        Form {
            // Apple-Standard Liquid Glass Configuration
            Section {
                MGGlassToggle("Enable Apple Liquid Glass", isOn: $engine.glassConfig.enabled)

                if engine.glassConfig.enabled {
                    Picker("Glass Appearance", selection: $engine.glassConfig.variant) {
                        ForEach(GlassVariant.allCases) { variant in
                            Text(variant.rawValue).tag(variant)
                        }
                    }

                    Picker("Interactive Response", selection: $engine.glassConfig.interactionResponse) {
                        ForEach(InteractionResponseLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Picker("Fluid Morphing Physics", selection: $engine.glassConfig.morphingMode) {
                        ForEach(MorphingMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            engine.resetGlassDefaults()
                        }
                    } label: {
                        Label("Reset to Apple Defaults", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)

                    // Live Interactive Optical Testing Playground
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live Optical Playground")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ZStack {
                            // Colorful Underflow Test Stripes (Visible Through Transparent Glass)
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
                            }
                            .frame(height: 70)
                            .opacity(0.85)

                            // Live Liquid Glass Pods Floating Over the Stripes
                            HStack(spacing: 12) {
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
                            .padding(.horizontal, 10)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 6)
                }
            } header: {
                Text("Liquid Glass Material & Optics")
            } footer: {
                Text("Applies Apple's native dynamic translucency, optical refraction, and fluid morphing transitions across all controls.")
            }

            // Managed Components & Runtimes
            Section("Installed Components & Runtimes") {
                ForEach(DependencyManager.shared.dependencies) { dep in
                    HStack {
                        Label(dep.name, systemImage: dep.category.icon)
                        Spacer()
                        switch dep.status {
                        case .installed(let ver):
                            Text("v\(ver) • Installed")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        case .notInstalled:
                            Text("Not Installed")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        case .outdated(_, let avail):
                            Text("Update Available (v\(avail))")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        case .downloading, .installing, .verifying:
                            ProgressView()
                                .controlSize(.small)
                        case .failed:
                            Text("Error")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                }

                Button {
                    DependencyManager.shared.inspectAllDependencies()
                } label: {
                    Label("Re-verify Components", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
            }

            // Graphics & Compatibility Runtimes
            Section("Graphics & Compatibility Runtime") {
                Picker("Wine Runner", selection: $wineVersion) {
                    Text("MacGaming Managed Wine Staging (Default)").tag("MacGaming Managed Wine Staging (Default)")
                    Text("Whisky / CrossOver Wine-GE-Proton").tag("Whisky / CrossOver Wine-GE-Proton")
                    Text("Wine-Staging 9.0 (Custom)").tag("Wine-Staging 9.0 (Custom)")
                }

                MGGlassToggle("Eventfd Synchronization (Esync)", isOn: $enableEsync)
                MGGlassToggle("Futex Synchronization (Fsync)", isOn: $enableFsync)
                MGGlassToggle("Persist Shader Pre-Caching on Disk", isOn: $shaderCacheEnabled)
                MGGlassToggle("Metal Performance HUD Overlay", isOn: $enableMetalHud)
            }

            // Application Permissions & Sandboxing
            Section("Application Permissions & Security") {
                HStack {
                    Label("Remembered File & Folder Access", systemImage: "lock.shield.fill")
                    Spacer()
                    Text("\(PermissionManager.shared.savedBookmarks.count) Saved Bookmarks")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("Accessibility / Gamepad Hooks", systemImage: "hand.tap.fill")
                    Spacer()
                    HStack(spacing: 8) {
                        Text(PermissionManager.shared.accessibilityStatus.rawValue)
                            .font(.system(size: 12))
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

                HStack {
                    Label("Game Controller / Input Monitoring", systemImage: "gamecontroller.fill")
                    Spacer()
                    Button("Open Privacy Settings") {
                        PermissionManager.shared.openSystemSettings(for: "inputMonitoring")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if !PermissionManager.shared.savedBookmarks.isEmpty {
                    Button(role: .destructive) {
                        PermissionManager.shared.clearAllSavedBookmarks()
                    } label: {
                        Label("Clear Saved File Access Permissions", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Hardware & System Specifications
            Section("System & Hardware") {
                LabeledContent("Chip", value: engine.hardware.chipName)
                LabeledContent("Unified Memory", value: "\(engine.hardware.memoryGB) GB")
                LabeledContent("macOS Version", value: engine.hardware.osVersion)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 720)
        .padding(20)
    }
}
