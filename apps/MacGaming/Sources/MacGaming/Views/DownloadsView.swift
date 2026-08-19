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

                // Active Provisioning Status Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Windows Steam Sandbox Container")
                                .font(.system(size: 14, weight: .semibold))
                            Text("~/Library/Application Support/MacGaming/launchers/steam")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Ready")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(5)
                    }

                    Divider()

                    HStack(spacing: 12) {
                        Menu {
                            Button {
                                engine.launchWindowsSteamSandbox(mode: .standard)
                            } label: {
                                Label("Launch Standard (Full UI)", systemImage: "app.window.checkmark")
                            }
                            Button {
                                engine.launchWindowsSteamSandbox(mode: .miniLibrary)
                            } label: {
                                Label("Launch Mini Library (Fast)", systemImage: "list.bullet.rectangle")
                            }
                            Button {
                                engine.launchWindowsSteamSandbox(mode: .gamepadUI)
                            } label: {
                                Label("Launch Big Picture UI", systemImage: "gamecontroller")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Launch Container")
                            }
                            .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button(action: {
                            let path = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/MacGaming/launchers/steam"
                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                Text("Show in Finder")
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

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
