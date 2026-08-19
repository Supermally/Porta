import SwiftUI

public struct GameDetailView: View {
    @ObservedObject var engine: EngineService
    let game: GameItem
    @State private var showingTroubleshootSheet = false
    @State private var showingSubmitSheet = false
    @State private var submissionPreset = "High"
    @State private var submissionNotes = ""

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero Banner
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [game.bannerColor.opacity(0.85), Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            StatusBadgeView(badge: game.badge)

                            Text(game.storefront)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.18))
                                .foregroundColor(.white)
                                .cornerRadius(5)

                            if game.isUniversalApp {
                                Text("Universal Application")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                        }

                        Text(game.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(18)
                }

                // Live Binary & Compatibility Analysis Card (Phase 1 Engine)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("Automated Binary Compatibility Analysis")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(game.engineType)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.12))
                            .cornerRadius(5)
                    }

                    let checklist = game.analysisChecklist.isEmpty ? [
                        game.isNative ? "✓ Official Apple Silicon native Mach-O binary" : "✓ Windows 64-bit executable (x86-64)",
                        game.isNative ? "✓ Direct Metal 3 hardware acceleration" : (game.isUnityGame ? "✓ Unity Engine detected (-force-d3d12 active)" : "✓ Direct3D Metal 3 pipeline mapped"),
                        "✓ No incompatible kernel anti-cheat detected",
                        "✓ Auto-tuned for \(engine.hardware.chipName)"
                    ] : game.analysisChecklist

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(checklist, id: \.self) { item in
                            HStack(spacing: 6) {
                                Text(item)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(item.contains("✗") ? .red : (item.contains("⚠") ? .orange : .primary.opacity(0.9)))
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )

                // Primary Action / Play / Benchmark Bar
                HStack(spacing: 10) {
                    Button(action: {
                        if engine.isGameModeActive {
                            engine.stopGame()
                        } else {
                            engine.launchGame(game)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: engine.isGameModeActive ? "stop.fill" : (game.badge == .unsupported ? "lock.fill" : "play.fill"))
                            Text(engine.isGameModeActive ? "Stop Session" : game.badge.actionTitle)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(minWidth: 180)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(engine.isGameModeActive ? .red : (game.badge == .unsupported ? .gray : (game.isNative ? .green : .blue)))
                    .disabled(game.badge == .unsupported)

                    Button(action: {
                        engine.runBenchmark(for: game)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.needle")
                            Text(engine.isBenchmarking ? "Recording..." : "Benchmark FPS")
                        }
                        .font(.system(size: 13))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(engine.isBenchmarking)

                    Button(action: {
                        engine.runTroubleshooter(for: game)
                        showingTroubleshootSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Troubleshoot")
                        }
                        .font(.system(size: 13))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        showingSubmitSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Submit Report")
                        }
                        .font(.system(size: 13))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)

                    if engine.isLaunching || engine.isBenchmarking {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    Spacer()
                }

                // Launch Status / Telemetry Diagnostic Box
                if let msg = engine.launchOutputMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session Diagnostics & Telemetry:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(msg)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.8))
                            .cornerRadius(8)
                    }
                }

                // Live Benchmark Telemetry Card (if benchmark run)
                if !engine.benchmarkSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.blue)
                            Text("Live Session Telemetry — \(engine.hardware.chipName)")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("Avg: \(Int(engine.benchmarkSamples.map(\.fps).reduce(0, +) / Double(engine.benchmarkSamples.count))) FPS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }

                        // Bar visualizer
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(engine.benchmarkSamples) { sample in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.fps >= 55.0 ? Color.green : (sample.fps >= 30.0 ? Color.yellow : Color.red))
                                    .frame(height: max(10, CGFloat(sample.fps) * 0.8))
                            }
                        }
                        .frame(height: 60)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(6)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                Divider()

                // Translation & Tuning Quick Toggles (Windows compatibility only)
                if !game.isNative {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation & Performance Controls")
                            .font(.system(size: 15, weight: .bold))

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Graphics Backend:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Button(action: {
                                        engine.setGraphicsBackend(for: game.id, useD3DMetal: true)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "applelogo")
                                            Text("D3DMetal (GPTK)")
                                        }
                                        .font(.system(size: 11, weight: game.useD3DMetal ? .bold : .regular))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(game.useD3DMetal ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(game.useD3DMetal ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        engine.setGraphicsBackend(for: game.id, useD3DMetal: false)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "cube.fill")
                                            Text("DXVK (Vulkan)")
                                        }
                                        .font(.system(size: 11, weight: !game.useD3DMetal ? .bold : .regular))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(!game.useD3DMetal ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(!game.useD3DMetal ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider().frame(height: 36)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Overlays & HUD:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Button(action: {
                                        engine.toggleHud(for: game.id)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: game.enableHud ? "gauge.with.needle.fill" : "gauge.with.needle")
                                            Text("Metal HUD: \(game.enableHud ? "ON" : "OFF")")
                                        }
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(game.enableHud ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider().frame(height: 36)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Display Resolution & Scaling:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Menu {
                                    Button("Native Fullscreen") {
                                        engine.setResolution(for: game.id, resolution: "Native")
                                    }
                                    Button("Virtual Desktop 1920x1080 (1080p)") {
                                        engine.setResolution(for: game.id, resolution: "1920x1080")
                                    }
                                    Button("Virtual Desktop 1280x720 (720p)") {
                                        engine.setResolution(for: game.id, resolution: "1280x720")
                                    }
                                    Button("Retro Windowed 640x480 (4:3)") {
                                        engine.setResolution(for: game.id, resolution: "640x480")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "display")
                                        Text(game.displayResolution)
                                    }
                                    .font(.system(size: 11))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(6)
                                }
                                .menuStyle(.borderlessButton)
                            }

                            if game.configUtilityPath != nil {
                                Divider().frame(height: 36)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Game Settings:")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Button(action: {
                                        engine.launchConfigUtility(for: game)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "gamecontroller.fill")
                                            Text("Configure Controls")
                                        }
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.18))
                                        .foregroundColor(.purple)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)

                        // Engine & Unity Renderer Flags Override
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.accentColor)
                                Text("Unity / Engine Renderer Overrides:")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                                if !game.customLaunchArgs.isEmpty {
                                    Button("Reset Args") {
                                        engine.setLaunchArgs(for: game.id, args: "")
                                    }
                                    .font(.system(size: 10))
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                }
                            }

                            HStack(spacing: 8) {
                                Button(action: {
                                    engine.setGraphicsBackend(for: game.id, useD3DMetal: true)
                                    engine.setLaunchArgs(for: game.id, args: "-force-d3d12")
                                }) {
                                    Text("⚡ Force DX12 (-force-d3d12)")
                                        .font(.system(size: 10, weight: game.customLaunchArgs.contains("-force-d3d12") ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(game.customLaunchArgs.contains("-force-d3d12") ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(game.customLaunchArgs.contains("-force-d3d12") ? .white : .primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    engine.setGraphicsBackend(for: game.id, useD3DMetal: false)
                                    engine.setLaunchArgs(for: game.id, args: "-force-vulkan")
                                }) {
                                    Text("🌋 Force Vulkan (-force-vulkan)")
                                        .font(.system(size: 10, weight: game.customLaunchArgs.contains("-force-vulkan") ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(game.customLaunchArgs.contains("-force-vulkan") ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(game.customLaunchArgs.contains("-force-vulkan") ? .white : .primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    engine.setGraphicsBackend(for: game.id, useD3DMetal: false)
                                    engine.setLaunchArgs(for: game.id, args: "-force-d3d11")
                                }) {
                                    Text("🧱 Force DX11 (-force-d3d11)")
                                        .font(.system(size: 10, weight: game.customLaunchArgs.contains("-force-d3d11") ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(game.customLaunchArgs.contains("-force-d3d11") ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(game.customLaunchArgs.contains("-force-d3d11") ? .white : .primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    engine.setGraphicsBackend(for: game.id, useD3DMetal: false)
                                    engine.setLaunchArgs(for: game.id, args: "-force-glcore")
                                }) {
                                    Text("⚙️ OpenGL Core (-force-glcore)")
                                        .font(.system(size: 10, weight: game.customLaunchArgs.contains("-force-glcore") ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(game.customLaunchArgs.contains("-force-glcore") ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(game.customLaunchArgs.contains("-force-glcore") ? .white : .primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
                        .cornerRadius(8)
                    }

                    // Companion Programs (Parallel Execution) Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "square.split.2x1.fill")
                                .foregroundColor(.accentColor)
                            Text("Companion Programs (Run in Parallel)")
                                .font(.system(size: 15, weight: .bold))

                            Spacer()

                            Button(action: {
                                engine.addCompanionProgram(for: game)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Companion .exe")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if game.companionPrograms.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("No companion programs configured. Add mod tools, trainers, or overlay utilities to launch concurrently in the same prefix container.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(game.companionPrograms) { comp in
                                    HStack {
                                        Toggle("", isOn: Binding(
                                            get: { comp.isEnabled },
                                            set: { _ in engine.toggleCompanionProgram(game: game, companionPath: comp.path) }
                                        ))
                                        .toggleStyle(.checkbox)
                                        .labelsHidden()

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comp.name)
                                                .font(.system(size: 12, weight: .semibold))
                                            Text(comp.path)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        Text(comp.isEnabled ? "Runs Parallel" : "Disabled")
                                            .font(.system(size: 10, weight: .semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(comp.isEnabled ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                                            .foregroundColor(comp.isEnabled ? .green : .secondary)
                                            .cornerRadius(4)
                                    }
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .cornerRadius(8)

                    Divider()
                }

                // Two-Column Grid: Configuration & Mac Recommendations
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Compatibility Configuration")
                            .font(.system(size: 15, weight: .bold))

                        DetailCard(title: "Runtime Environment", value: game.runtime)
                        DetailCard(title: "Anti-Cheat Protection", value: game.antiCheatStatus ?? "None Required")
                        DetailCard(title: "Storefront Source", value: "\(game.storefront) Library")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tuned for \(engine.hardware.chipName)")
                            .font(.system(size: 15, weight: .bold))

                        DetailCard(title: "Recommended Preset", value: game.hardwarePreset)
                        DetailCard(title: "Target Performance", value: "\(game.targetFps) FPS Target")
                        DetailCard(title: "Community Rating", value: "\(game.rating)% Verified Working")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Acquisition & Ownership Layer Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: game.acquisitionType.icon)
                            .foregroundColor(game.acquisitionType.badgeColor)
                        Text("Acquisition & Ownership Layer")
                            .font(.system(size: 15, weight: .bold))

                        Spacer()

                        Text(game.acquisitionType.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(game.acquisitionType.badgeColor.opacity(0.18))
                            .foregroundColor(game.acquisitionType.badgeColor)
                            .cornerRadius(6)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(game.acquisitionType == .nativeStorefront ? "Path ①: Native macOS build running directly via Apple Silicon Metal pipeline." :
                                 (game.acquisitionType == .windowsLauncherRuntime ? "Path ③: Sandboxed Windows Steam / Launcher container for official DRM, downloads & cloud saves." :
                                 (game.acquisitionType == .storefrontIntegration ? "Path ②: Official storefront integration running inside isolated prefix." :
                                 "Path ④: Transferred PC game folder with automated companion process supervisor.")))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if !game.installPath.isEmpty {
                                Text("Path: \(game.installPath)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if game.storefront == "Steam" || game.acquisitionType == .windowsLauncherRuntime {
                            Button(action: {
                                engine.launchWindowsSteamSandbox(appId: game.id.replacingOccurrences(of: "steam_", with: ""))
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "shippingbox.fill")
                                    Text("Open Windows Steam")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if !game.installPath.isEmpty {
                            Button(action: {
                                NSWorkspace.shared.selectFile(game.executablePath.isEmpty ? game.installPath : game.executablePath, inFileViewerRootedAtPath: game.installPath)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder.fill")
                                    Text("Show in Finder")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Community Reports & Reviews Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.accentColor)
                        Text("Crowdsourced Community Reports")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                    }

                    ForEach(engine.communityReviews) { review in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(review.userHandle)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(review.chipName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(review.tierName)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(review.tierColor.opacity(0.18))
                                    .foregroundColor(review.tierColor)
                                    .cornerRadius(4)
                            }
                            Text(review.comment)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingTroubleshootSheet) {
            TroubleshootModalView(engine: engine, isPresented: $showingTroubleshootSheet)
        }
        .sheet(isPresented: $showingSubmitSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Submit Compatibility Report")
                    .font(.system(size: 18, weight: .bold))

                Text("Share performance notes and settings for '\(game.title)' on \(engine.hardware.chipName).")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommended Preset:")
                        .font(.system(size: 12, weight: .medium))
                    Picker("", selection: $submissionPreset) {
                        Text("High Preset (60 FPS)").tag("High")
                        Text("Medium Preset (60 FPS)").tag("Medium")
                        Text("Low / FSR Performance").tag("Low")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes / DLL Overrides:")
                        .font(.system(size: 12, weight: .medium))
                    TextField("e.g. Disabled HairWorks, locked 60 FPS without stutters.", text: $submissionNotes)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button("Cancel") { showingSubmitSheet = false }
                    Button("Submit to Community") {
                        engine.submitProfile(for: game, preset: submissionPreset, notes: submissionNotes)
                        showingSubmitSheet = false
                        submissionNotes = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 460)
        }
    }
}

struct TroubleshootModalView: View {
    @ObservedObject var engine: EngineService
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.accentColor)
                Text("Automated Diagnostics & Troubleshooter")
                    .font(.system(size: 18, weight: .bold))
            }

            if let report = engine.activeTroubleshootReport {
                Text(report.summary)
                    .font(.system(size: 12))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(report.hasCriticalIssues ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                    .cornerRadius(6)

                ForEach(report.findings) { finding in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(finding.title)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text(finding.severity)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(finding.severity == "CRITICAL" ? Color.red.opacity(0.18) : Color.blue.opacity(0.18))
                                .foregroundColor(finding.severity == "CRITICAL" ? .red : .blue)
                                .cornerRadius(4)
                        }

                        Text(finding.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        if let snippet = finding.logSnippet {
                            Text("Trace: \(snippet)")
                                .font(.system(size: 10, design: .monospaced))
                                .padding(4)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(4)
                        }

                        HStack {
                            Text("Remedy: \(finding.recommendedAction)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                            Spacer()
                            if let cmd = finding.autoFixCommand {
                                Button("Apply Fix (\(cmd))") {}
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }

            HStack {
                Spacer()
                Button("Close") { isPresented = false }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}

struct DetailCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
