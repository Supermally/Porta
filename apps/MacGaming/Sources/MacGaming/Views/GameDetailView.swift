import SwiftUI
import AppKit

public struct GameDetailView: View {
    @ObservedObject var engine: EngineService
    let game: GameItem

    @State private var showingDeveloperDetails = false
    @State private var showingAdvancedSettings = false
    @State private var showingTroubleshootSheet = false
    @Namespace private var glassNamespace

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Hero Artwork Banner with Liquid Glass Specular Rim
                ZStack(alignment: .bottomLeading) {
                    if let heroPath = game.localHeroPath ?? game.localPosterPath,
                       let nsImage = NSImage(contentsOfFile: heroPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 240)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.1),
                                        Color.black.opacity(0.85)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.8),
                                    Color.indigo.opacity(0.6),
                                    Color.black.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            HStack {
                                Spacer()
                                Image(systemName: game.isNative ? "apple.logo" : "gamecontroller.fill")
                                    .font(.system(size: 96))
                                    .foregroundColor(.white.opacity(0.1))
                                    .padding(.trailing, 40)
                            }
                        }
                        .frame(height: 220)
                    }

                    // Hero Information & Compatibility Badge Group
                    VStack(alignment: .leading, spacing: 8) {
                        GlassEffectContainer(spacing: 8) {
                            CompatibilityBadgeView(game.badge)
                                .glassEffectID("gameBadge_\(game.id)", in: glassNamespace)

                            Text(game.storefront)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .glassEffectID("gameStorefront_\(game.id)", in: glassNamespace)
                        }

                        Text(game.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(game.developerName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(22)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.6), location: 0.0),
                                    .init(color: Color.white.opacity(0.1), location: 0.5),
                                    .init(color: Color.white.opacity(0.3), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)

                // Coordinated Liquid Glass Action Bar
                HStack {
                    MGActionGroup(spacing: 8) {
                        MGPlayButton(
                            state: engine.isLaunching ? (engine.isGameModeActive ? .running : .launching) : .idle,
                            onPlay: { engine.launchGame(game) },
                            onStop: { engine.stopGame() }
                        )

                        Button {
                            showingAdvancedSettings.toggle()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.glass)

                        Button {
                            showingTroubleshootSheet = true
                        } label: {
                            Label("Diagnostics", systemImage: "stethoscope")
                        }
                        .buttonStyle(.glass)
                    }

                    Spacer()
                }

                // Session Status / Output Diagnostics
                if let msg = engine.launchOutputMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session Status")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(msg)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                // Compatibility Breakdown Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Compatibility")
                        .font(.headline)

                    VStack(spacing: 8) {
                        CompatibilityItemRow(
                            title: "Apple Silicon",
                            detail: game.isNative ? "Native ARM64 Mach-O execution" : "Rosetta 2 translation bridge active",
                            isSupported: true
                        )

                        CompatibilityItemRow(
                            title: "Graphics Pipeline",
                            detail: game.isNative ? "Metal 3 Hardware Accelerated" : (game.isUnityGame ? "DirectX 12 → Apple D3DMetal" : "DirectX 11/12 → Metal Translation"),
                            isSupported: true
                        )

                        CompatibilityItemRow(
                            title: "Game Controller",
                            detail: "Apple GameController framework active (DualSense, Xbox, Switch Pro)",
                            isSupported: true
                        )

                        CompatibilityItemRow(
                            title: "Anti-Cheat & DRM",
                            detail: game.antiCheatStatus ?? "Verified compatible with Mac Gaming runtime",
                            isSupported: game.badge != .unsupported
                        )
                    }
                }

                // Performance on This Mac
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Performance on This Mac")
                            .font(.headline)
                        Spacer()
                        Text(engine.hardware.chipName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        PerformanceMetricBox(title: "Target Framerate", value: "\(game.targetFps) FPS", subtitle: nil)
                        PerformanceMetricBox(title: "Recommended Preset", value: game.hardwarePreset, subtitle: nil)
                        PerformanceMetricBox(title: "Community Verdict", value: "\(game.rating)% Verified", subtitle: nil, isHighlighted: true)
                    }
                }

                // Save States & Progress Instance Vault
                GameSaveInstancesView(engine: engine, game: game)

                // Advanced Settings & Library Management
                DisclosureGroup(
                    isExpanded: $showingAdvancedSettings,
                    content: {
                        VStack(alignment: .leading, spacing: 14) {
                            if !game.runtime.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Runtime:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(game.runtime)
                                        .font(.system(size: 11, design: .monospaced))
                                }
                            }

                            if !game.installPath.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Install Path:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(game.installPath)
                                        .font(.system(size: 11, design: .monospaced))
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Graphics Translation Layer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Picker("Backend", selection: Binding(
                                    get: { game.useD3DMetal },
                                    set: { engine.setGraphicsBackend(for: game.id, useD3DMetal: $0) }
                                )) {
                                    Text("Apple D3DMetal 2.0").tag(true)
                                    Text("DXVK (Vulkan)").tag(false)
                                }
                                .pickerStyle(.segmented)
                            }

                            Toggle("Metal Performance HUD Overlay", isOn: Binding(
                                get: { game.enableHud },
                                set: { _ in engine.toggleHud(for: game.id) }
                            ))

                            if game.acquisitionType == .existingFiles || game.storefront == "Local / Custom" || game.isUniversalApp {
                                Divider()
                                    .padding(.vertical, 4)

                                Button(role: .destructive) {
                                    engine.deleteImportedGame(game)
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove Game from Library")
                                    }
                                    .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 4)
                    },
                    label: {
                        Label("Advanced Settings & Library Management", systemImage: "gearshape.2")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                )
            }
            .padding(24)
        }
        .sheet(isPresented: $showingTroubleshootSheet) {
            if let report = engine.activeTroubleshootReport {
                DiagnosticsSheetView(report: report, engine: engine) {
                    showingTroubleshootSheet = false
                }
            }
        }
    }
}

// MARK: - Compatibility Item Row
struct CompatibilityItemRow: View {
    let title: String
    let detail: String
    let isSupported: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? Color.green : Color.red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Performance Metric Box
struct PerformanceMetricBox: View {
    let title: String
    let value: String
    let subtitle: String?
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(isHighlighted ? Color.green : .primary)
                .lineLimit(1)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
