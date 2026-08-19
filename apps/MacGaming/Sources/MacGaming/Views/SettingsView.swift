import SwiftUI

public struct SettingsView: View {
    @State private var isAdvancedMode: Bool = false
    @State private var performancePreset: String = "Balanced"
    @State private var graphicsPreset: String = "Recommended"
    @State private var wineVersion: String = "Wine-CXP-23.7 (Default)"
    @State private var enableEsync: Bool = true
    @State private var enableFsync: Bool = true
    @State private var enableDxvkHud: Bool = false
    @State private var enableMetalHud: Bool = false
    @State private var shaderCacheEnabled: Bool = true

    public var body: some View {
        Form {
            Section {
                Toggle("Enable Advanced Mode", isOn: $isAdvancedMode)
                    .font(.system(size: 13, weight: .semibold))
            }

            if !isAdvancedMode {
                // Simple Mode
                Section(header: Text("Simple Mode Settings")) {
                    Picker("Performance Profile", selection: $performancePreset) {
                        Text("Battery Saver").tag("Battery Saver")
                        Text("Balanced (Recommended)").tag("Balanced")
                        Text("Max Performance").tag("Max Performance")
                    }

                    Picker("Graphics Settings", selection: $graphicsPreset) {
                        Text("Automatic / Native").tag("Automatic")
                        Text("Recommended for Hardware").tag("Recommended")
                        Text("Low Latency").tag("Low Latency")
                    }
                }
            } else {
                // Advanced Mode
                Section(header: Text("Compatibility Runtimes")) {
                    Picker("Wine Runner", selection: $wineVersion) {
                        Text("Wine-CXP-23.7 (Default)").tag("Wine-CXP-23.7 (Default)")
                        Text("Wine-GE-Proton-8.26").tag("Wine-GE-Proton-8.26")
                        Text("Wine-Staging 9.0").tag("Wine-Staging 9.0")
                    }

                    Toggle("Enable Esync (Eventfd Synchronization)", isOn: $enableEsync)
                    Toggle("Enable Fsync (Futex Synchronization)", isOn: $enableFsync)
                    Toggle("Persist Shader Pre-Caching", isOn: $shaderCacheEnabled)
                }

                Section(header: Text("Graphics & Overlays")) {
                    Toggle("Enable Metal Performance HUD", isOn: $enableMetalHud)
                    Toggle("Enable DXVK Frame Counter & HUD", isOn: $enableDxvkHud)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 550)
    }
}
