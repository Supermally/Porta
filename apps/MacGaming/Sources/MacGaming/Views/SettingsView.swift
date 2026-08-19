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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preferences")
                        .font(.system(size: 28, weight: .bold))
                    Text("Configure Liquid Glass optics, refraction intensity, and compatibility runtimes.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Liquid Glass Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .bold))
                        Text("Liquid Glass Materials & Optics")
                            .font(.system(size: 17, weight: .bold))
                        Spacer()
                    }

                    Toggle("Enable Liquid Glass Materials & Chromatic Aura", isOn: $engine.liquidGlassEnabled)
                        .font(.system(size: 14, weight: .semibold))

                    if engine.liquidGlassEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Refraction & Specular Intensity:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(engine.liquidGlassIntensity * 100))%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }

                            Slider(value: $engine.liquidGlassIntensity, in: 0.1...1.0, step: 0.05)
                        }

                        // Live Liquid Glass Optical Bubble Preview
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Live Glass Optical Preview")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Dynamic chromatic aura pass-through, specular rim reflection, and continuous curvature.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sample Glass Pod") {}
                                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity))
                        }
                        .padding(16)
                        .liquidGlassBubble(cornerRadius: 18, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                    }
                }
                .padding(20)
                .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Compatibility Engine & Runtimes
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .bold))
                        Text("Compatibility Runtime & Metal")
                            .font(.system(size: 17, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 12) {
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
                .padding(20)
                .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            }
            .padding(24)
            .frame(maxWidth: 700)
        }
    }
}
