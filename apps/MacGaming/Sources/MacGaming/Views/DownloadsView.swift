import SwiftUI

public struct DownloadsView: View {
    @ObservedObject var engine: EngineService

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Liquid Glass Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Downloads & Provisioning")
                        .font(.system(size: 24, weight: .bold))
                    Text("Background container provisioning, automated runtime downloads, and offline installers.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)



                // Offline Installers & Cache Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Cached Offline Installers & Setups")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text("Mac Gaming automatically caches and executes offline DRM-free installers (.exe / .dmg) with zero user intervention.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Button(action: {
                        engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Install Offline Setup (.exe)...")
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
