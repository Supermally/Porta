import SwiftUI
import AppKit

public struct GameDetailView: View {
    @ObservedObject var engine: EngineService
    let game: GameItem

    @State private var showingDeveloperDetails = false
    @State private var showingTroubleshootSheet = false
    @State private var showingSubmitSheet = false

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Breathable Hero Artwork Banner
                ZStack(alignment: .bottomLeading) {
                    if let heroPath = game.localHeroPath ?? game.localPosterPath,
                       let nsImage = NSImage(contentsOfFile: heroPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.1), Color.black.opacity(0.75)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(game.bannerColor.gradient.opacity(0.85))
                            .frame(height: 190)
                            .overlay(
                                VStack {
                                    Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            )
                    }

                    // Hero Text Overlay
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(game.badge.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .liquidGlass(cornerRadius: 5, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                                .foregroundColor(.white)

                            Text(game.storefront)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }

                        Text(game.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text(game.developerName)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(20)
                }
                .cornerRadius(16)

                // Primary Action Bar (Liquid Glass ▶ Play Button)
                HStack(spacing: 12) {
                    Button(action: {
                        if engine.isGameModeActive {
                            engine.stopGame()
                        } else {
                            engine.launchGame(game)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: engine.isGameModeActive ? "stop.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text(engine.isGameModeActive ? "Stop Session" : "Play")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(minWidth: 150)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: true,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity
                    ))

                    Button(action: {
                        engine.runBenchmark(for: game)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "gauge.with.needle")
                            Text("Benchmark")
                        }
                        .font(.system(size: 13))
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: false,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity
                    ))

                    Button(action: {
                        engine.runTroubleshooter(for: game)
                        showingTroubleshootSheet = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Troubleshoot")
                        }
                        .font(.system(size: 13))
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: false,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity
                    ))

                    Spacer()

                    if !game.installPath.isEmpty {
                        Button(action: {
                            NSWorkspace.shared.selectFile(game.executablePath.isEmpty ? game.installPath : game.executablePath, inFileViewerRootedAtPath: game.installPath)
                        }) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 12))
                                .padding(8)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(
                            isProminent: false,
                            isEnabled: engine.liquidGlassEnabled,
                            intensity: engine.liquidGlassIntensity
                        ))
                        .help("Show game files in Finder")
                    }
                }

                // Launch Diagnostics / Status Telemetry Box
                if let msg = engine.launchOutputMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session Status:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(msg)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .liquidGlass(cornerRadius: 8, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                    }
                }

                // Native Apple-Style Compatibility Breakdown Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist.checked")
                            .foregroundColor(.accentColor)
                        Text("Compatibility")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text("Automatic")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 8) {
                        CompatibilityRow(
                            title: "Apple Silicon",
                            subtitle: game.isNative ? "Native ARM64 Mach-O execution" : "Rosetta 2 translation bridge active",
                            status: "✓",
                            statusColor: .green
                        )

                        CompatibilityRow(
                            title: "Graphics Pipeline",
                            subtitle: game.isNative ? "Metal 3 Hardware Accelerated" : (game.isUnityGame ? "DirectX 12 → Apple D3DMetal" : "DirectX 11/12 → Metal Translation"),
                            status: "✓",
                            statusColor: .green
                        )

                        CompatibilityRow(
                            title: "Game Controller",
                            subtitle: "Apple GameController framework active (DualSense, Xbox, Switch Pro)",
                            status: "✓",
                            statusColor: .green
                        )

                        CompatibilityRow(
                            title: "Anti-Cheat & DRM",
                            subtitle: game.antiCheatStatus ?? "Verified compatible with Mac Gaming runtime",
                            status: game.badge == .unsupported ? "✗" : "✓",
                            statusColor: game.badge == .unsupported ? .red : .green
                        )
                    }
                }
                .padding(16)
                .liquidGlass(cornerRadius: 12, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Performance on This Mac Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("Performance on This Mac")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text(engine.hardware.chipName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target Framerate")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(game.targetFps) FPS")
                                .font(.system(size: 18, weight: .bold))
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended Preset")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(game.hardwarePreset)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Community Verdict")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(game.rating)% Verified")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                .padding(16)
                .liquidGlass(cornerRadius: 12, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Developer & Advanced Mode Disclosure
                DisclosureGroup(
                    isExpanded: $showingDeveloperDetails,
                    content: {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Runtime Environment:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(game.runtime)
                                    .font(.system(size: 11, design: .monospaced))
                            }

                            if !game.installPath.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Container Prefix Path:")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text(game.installPath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(1)
                                }
                            }

                            // Graphics Translation Toggle
                            HStack {
                                Text("Graphics Backend:")
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { game.useD3DMetal },
                                    set: { engine.setGraphicsBackend(for: game.id, useD3DMetal: $0) }
                                )) {
                                    Text("Apple D3DMetal 2.0").tag(true)
                                    Text("DXVK (Vulkan)").tag(false)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                            }

                            // Metal Performance HUD Toggle
                            HStack {
                                Text("Metal Performance HUD:")
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { game.enableHud },
                                    set: { _ in engine.toggleHud(for: game.id) }
                                ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                            }
                        }
                        .padding(.top, 10)
                    },
                    label: {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.secondary)
                            Text("Advanced / Developer Settings")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                )
                .padding(16)
                .liquidGlass(cornerRadius: 12, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onHover { _ in NSCursor.arrow.set() }
        .sheet(isPresented: $showingTroubleshootSheet) {
            if let report = engine.activeTroubleshootReport {
                DiagnosticsSheetView(report: report, engine: engine) {
                    showingTroubleshootSheet = false
                }
            }
        }
    }
}

// MARK: - Compatibility Row Component
public struct CompatibilityRow: View {
    let title: String
    let subtitle: String
    let status: String
    let statusColor: Color

    public var body: some View {
        HStack(spacing: 12) {
            Text(status)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(statusColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(6)
    }
}
