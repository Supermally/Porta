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
            // Apple-Standard Liquid Glass & Materials Editor
            Section {
                Toggle("Enable Apple Liquid Glass Controls", isOn: $engine.liquidGlassEnabled)

                if engine.liquidGlassEnabled {
                    Toggle("Reduce Transparency (Accessibility Mode)", isOn: $engine.reduceTransparency)

                    if !engine.reduceTransparency {
                        // 1. Optical Transparency Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Optical Transparency", systemImage: "square.2.layers.3d.top.filled")
                                Spacer()
                                Text("\(Int(engine.glassTransparency * 100))%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $engine.glassTransparency, in: 0.0...1.0, step: 0.05)
                            HStack {
                                Text("Opaque (0%)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Crystal Clear (100%)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        // 2. Specular Rim & Flare Intensity Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Specular Rim & Flare Reflection", systemImage: "sparkles")
                                Spacer()
                                Text("\(Int(engine.glassSpecularIntensity * 100))%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $engine.glassSpecularIntensity, in: 0.0...1.0, step: 0.05)
                            HStack {
                                Text("Matte (0%)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("High-Gloss (100%)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        // 3. Blur Scattering Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Optical Blur & Diffusion", systemImage: "aqi.medium")
                                Spacer()
                                Text("\(Int(engine.glassBlurRadius)) px")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $engine.glassBlurRadius, in: 5.0...40.0, step: 1.0)
                        }
                        .padding(.vertical, 4)

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                engine.resetGlassDefaults()
                            }
                        } label: {
                            Label("Reset to Apple Defaults", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                    }

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
                                PlayButton(isPlaying: false) {}

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
                Text("Liquid Glass Optics & Materials")
            } footer: {
                Text("Independently tunes light transmission (transparency), 3D specular rim reflections, and background diffusion across all floating panels and buttons.")
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
        .frame(maxWidth: 720)
        .padding(20)
    }
}
