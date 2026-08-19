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

            Section("System & Hardware") {
                LabeledContent("Chip", value: engine.hardware.chipName)
                LabeledContent("Unified Memory", value: "\(engine.hardware.memoryGB) GB")
                LabeledContent("macOS Version", value: engine.hardware.osVersion)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 650)
        .padding(20)
    }
}
