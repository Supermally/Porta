import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: EngineService
    @State private var isAdvancedMode: Bool = false
    @State private var performancePreset: String = "Balanced"
    @State private var graphicsPreset: String = "Recommended"
    @State private var wineVersion: String = "Apple D3DMetal + Wine-CX-23.7 (Default)"
    @State private var enableEsync: Bool = true
    @State private var enableFsync: Bool = true
    @State private var enableDxvkHud: Bool = false
    @State private var enableMetalHud: Bool = false
    @State private var shaderCacheEnabled: Bool = true

    public init(engine: EngineService) {
        self._engine = ObservedObject(wrappedValue: engine)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferences")
                        .font(.system(size: 24, weight: .bold))
                    Text("Configure Liquid Glass materials, compatibility runtimes, and system integration.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Liquid Glass Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.accentColor)
                        Text("Liquid Glass Materials & Appearance")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                    }

                    Toggle("Enable Liquid Glass Materials", isOn: $engine.liquidGlassEnabled)
                        .font(.system(size: 13, weight: .semibold))

                    if engine.liquidGlassEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Refraction & Specular Intensity:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(engine.liquidGlassIntensity * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }

                            Slider(value: $engine.liquidGlassIntensity, in: 0.1...1.0, step: 0.05)
                        }

                        // Live Liquid Glass Preview Card
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Live Glass Preview")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Specular rim lighting, dynamic refraction, and ambient occlusion.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sample Action") {}
                                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity))
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 10, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                    }
                }
                .padding(18)
                .liquidGlass(cornerRadius: 12, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Compatibility Engine & Runtimes
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(.accentColor)
                        Text("Compatibility Runtime & Metal")
                            .font(.system(size: 15, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 10) {
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
                    .font(.system(size: 13))
                }
                .padding(18)
                .liquidGlass(cornerRadius: 12, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            }
            .padding(24)
            .frame(maxWidth: 680)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
