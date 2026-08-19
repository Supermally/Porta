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
            VStack(alignment: .leading, spacing: 22) {
                // Floating Large Rounded Glass Hero Banner
                ZStack(alignment: .bottomLeading) {
                    if let heroPath = game.localHeroPath ?? game.localPosterPath,
                       let nsImage = NSImage(contentsOfFile: heroPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.15),
                                        Color.black.opacity(0.85)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(game.bannerColor.gradient.opacity(0.85))
                            .frame(height: 210)
                            .overlay(
                                VStack {
                                    Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                                        .font(.system(size: 54))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            )
                    }

                    // Hero Text & Floating Glass Badges
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Text(game.badge.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity, tint: game.badge.color)
                                .foregroundColor(.white)

                            Text(game.storefront)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                                .foregroundColor(.white)
                        }

                        Text(game.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text(game.developerName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .liquidGlassBubble(cornerRadius: 26, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Floating Liquid Glass Action Controls
                HStack(spacing: 10) {
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
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: true,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity,
                        customTint: engine.isGameModeActive ? Color.red : Color.accentColor
                    ))
                    .fixedSize()

                    Button(action: {
                        engine.runBenchmark(for: game)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "gauge.with.needle")
                            Text("Benchmark")
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: false,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity
                    ))
                    .fixedSize()

                    Button(action: {
                        engine.runTroubleshooter(for: game)
                        showingTroubleshootSheet = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Troubleshoot")
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        isProminent: false,
                        isEnabled: engine.liquidGlassEnabled,
                        intensity: engine.liquidGlassIntensity
                    ))
                    .fixedSize()

                    if !game.installPath.isEmpty {
                        Button(action: {
                            NSWorkspace.shared.selectFile(game.executablePath.isEmpty ? game.installPath : game.executablePath, inFileViewerRootedAtPath: game.installPath)
                        }) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(LiquidGlassButtonStyle(
                            isProminent: false,
                            isEnabled: engine.liquidGlassEnabled,
                            intensity: engine.liquidGlassIntensity
                        ))
                        .fixedSize()
                        .help("Show game files in Finder")
                    }

                    Spacer()
                }

                // Launch Diagnostics / Status Telemetry Box
                if let msg = engine.launchOutputMessage {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Status:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(msg)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .liquidGlassBubble(cornerRadius: 16, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                    }
                }

                // Native Apple-Style Compatibility Breakdown Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "checklist.checked")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .bold))
                        Text("Compatibility")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text("Automatic")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 10) {
                        CompatibilityGlassRow(
                            title: "Apple Silicon",
                            subtitle: game.isNative ? "Native ARM64 Mach-O execution" : "Rosetta 2 translation bridge active",
                            status: "✓",
                            statusColor: .green,
                            engine: engine
                        )

                        CompatibilityGlassRow(
                            title: "Graphics Pipeline",
                            subtitle: game.isNative ? "Metal 3 Hardware Accelerated" : (game.isUnityGame ? "DirectX 12 → Apple D3DMetal" : "DirectX 11/12 → Metal Translation"),
                            status: "✓",
                            statusColor: .green,
                            engine: engine
                        )

                        CompatibilityGlassRow(
                            title: "Game Controller",
                            subtitle: "Apple GameController framework active (DualSense, Xbox, Switch Pro)",
                            status: "✓",
                            statusColor: .green,
                            engine: engine
                        )

                        CompatibilityGlassRow(
                            title: "Anti-Cheat & DRM",
                            subtitle: game.antiCheatStatus ?? "Verified compatible with Mac Gaming runtime",
                            status: game.badge == .unsupported ? "✗" : "✓",
                            statusColor: game.badge == .unsupported ? .red : .green,
                            engine: engine
                        )
                    }
                }
                .padding(18)
                .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                // Performance on This Mac Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .bold))
                        Text("Performance on This Mac")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text(engine.hardware.chipName)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .liquidGlassPill(isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Target Framerate")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(game.targetFps) FPS")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlassBubble(cornerRadius: 14, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Recommended Preset")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(game.hardwarePreset)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlassBubble(cornerRadius: 14, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Community Verdict")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(game.rating)% Verified")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlassBubble(cornerRadius: 14, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
                    }
                }
                .padding(18)
                .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)

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
                                .labelsHidden()
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
                        .padding(.top, 12)
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
                .padding(18)
                .liquidGlassBubble(cornerRadius: 24, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
            }
            .padding(24)
        }
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

// MARK: - Compatibility Glass Row Component
public struct CompatibilityGlassRow: View {
    let title: String
    let subtitle: String
    let status: String
    let statusColor: Color
    @ObservedObject var engine: EngineService

    public var body: some View {
        HStack(spacing: 14) {
            Text(status)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(statusColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassBubble(cornerRadius: 14, isEnabled: engine.liquidGlassEnabled, intensity: engine.liquidGlassIntensity)
    }
}
