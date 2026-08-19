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
            // Liquid Glass Materials Section
            Section {
                Toggle("Enable Apple Liquid Glass Controls", isOn: $engine.liquidGlassEnabled)

                if engine.liquidGlassEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Glass Transparency & Specular Intensity")
                            Spacer()
                            Text("\(Int(engine.liquidGlassIntensity * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $engine.liquidGlassIntensity, in: 0.10...1.0, step: 0.05)
                    }

                    // Live Interactive Liquid Glass Preview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live Preview")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            PlayButton(isPlaying: false) {}

                            GlassActionGroup(spacing: 8) {
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
                        .padding(8)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("Liquid Glass & Materials")
            } footer: {
                Text("Controls the translucency, light scattering, and specular rim reflection of Apple Liquid Glass controls across the application.")
            }

            // Graphics & Compatibility Runtimes
            Section("Graphics & Compatibility Runtime") {
                Picker("Wine Runner", selection: $wineVersion) {
                    Text("Apple D3DMetal + Wine-CX-23.7 (Default)").tag("Apple D3DMetal + Wine-CX-23.7 (Default)")
                    Text("Whisky / CrossOver Wine-GE-Proton").tag("Whisky / CrossOver Wine-GE-Proton")
                    Text("Wine-Staging 9.0 (Custom)").tag("Wine-Staging 9.0 (Custom)")
                }

                Toggle("Eventfd Synchronization (Esync)", isOn: $enableEsync)
                Toggle("Futex Synchronization (Fsync)", isOn: $enableFsync)
                Toggle("Persist Shader Pre-Caching on Disk", isOn: $shaderCacheEnabled)
                Toggle("Metal Performance HUD Overlay", isOn: $enableMetalHud)
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
        .frame(maxWidth: 680)
        .padding(20)
    }
}
