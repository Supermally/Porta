import SwiftUI
import AppKit

public struct GameDetailView: View {
    @ObservedObject var engine: EngineService
    let game: GameItem

    @State private var showingDeveloperDetails = false
    @State private var showingAdvancedSettings = false
    @State private var showingSettingsSheet = false
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
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 180)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.1), Color.black.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else if let appId = game.steamAppId, !appId.isEmpty {
                        let heroURL = URL(string: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appId)/library_hero.jpg")
                        CachedArtworkImageView(
                            url: heroURL,
                            contentMode: .fill,
                            placeholder: AnyView(
                                CachedArtworkImageView(
                                    url: URL(string: game.steamHeaderImageURL ?? ""),
                                    contentMode: .fill,
                                    placeholder: AnyView(defaultHeroGradient)
                                )
                            )
                        )
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 180)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.1), Color.black.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else if let headerURL = game.steamHeaderImageURL, let url = URL(string: headerURL) {
                        CachedArtworkImageView(
                            url: url,
                            contentMode: .fill,
                            placeholder: AnyView(defaultHeroGradient)
                        )
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 180)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.1), Color.black.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else {
                        defaultHeroGradient
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
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
                HStack(spacing: 8) {
                    Button(action: {
                        if engine.isLaunching {
                            engine.stopGame()
                        } else {
                            engine.launchGame(game)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: engine.isLaunching ? "stop.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text(engine.isLaunching ? "Running" : "Play")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 10, isProminent: true))
                    .fixedSize(horizontal: true, vertical: false)

                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 13, weight: .medium))
                            Text("Settings")
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 10, isProminent: false))
                    .fixedSize(horizontal: true, vertical: false)

                    Button(action: {
                        engine.runDiagnostics(for: game)
                        showingTroubleshootSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 13, weight: .medium))
                            Text("Diagnostics")
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 10, isProminent: false))
                    .fixedSize(horizontal: true, vertical: false)

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
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Performance on This Mac")
                            .font(.headline)
                        Spacer()
                        Text(engine.hardware.chipName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        PerformanceMetricBox(title: "Target FPS", value: "\(game.targetFps) FPS", subtitle: nil)
                        PerformanceMetricBox(title: "Preset", value: game.hardwarePreset, subtitle: nil)
                        PerformanceMetricBox(title: "Verdict", value: "\(game.rating)%", subtitle: nil, isHighlighted: true)
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
                                        .lineLimit(2)
                                        .truncationMode(.middle)
                                }
                            }

                            if !game.installPath.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Install Path:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(game.installPath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(2)
                                        .truncationMode(.middle)
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
                                .buttonStyle(.portaGlass(cornerRadius: 8))
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
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            GameSettingsSheetView(game: game, engine: engine) {
                showingSettingsSheet = false
            }
        }
        .sheet(isPresented: $showingTroubleshootSheet) {
            if let report = engine.activeTroubleshootReport {
                DiagnosticsSheetView(report: report, engine: engine) {
                    showingTroubleshootSheet = false
                }
            } else {
                DiagnosticsSheetView(
                    report: DiagnosticReportItem(
                        summary: "\(game.title) Translation & Runtime Environment Validation",
                        hasCriticalIssues: false,
                        findings: [
                            DiagnosticFindingItem(
                                title: "Architecture & Execution",
                                severity: "info",
                                description: game.isNative ? "Native Apple Silicon ARM64 Mach-O" : "Apple Rosetta 2 + Translation Bridge",
                                logSnippet: nil,
                                recommendedAction: "No action needed.",
                                autoFixCommand: nil
                            )
                        ]
                    ),
                    engine: engine
                ) {
                    showingTroubleshootSheet = false
                }
            }
        }
    }

    private var defaultHeroGradient: some View {
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
                    .font(.system(size: 72))
                    .foregroundColor(.white.opacity(0.12))
                    .padding(.trailing, 24)
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

// MARK: - Game Settings & Configuration Sheet View
public struct GameSettingsSheetView: View {
    let game: GameItem
    @ObservedObject var engine: EngineService
    let onDismiss: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                Text("\(game.title) Settings")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button("Done", action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Graphics Translation Pipeline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Graphics Translation Engine")
                            .font(.system(size: 13, weight: .semibold))
                        HStack(spacing: 10) {
                            Button(action: {
                                engine.setGraphicsBackend(for: game.id, useD3DMetal: true)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: game.useD3DMetal ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(game.useD3DMetal ? .blue : .secondary)
                                    Text("Apple D3DMetal (DirectX 11/12)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.portaGlass(cornerRadius: 8, isProminent: game.useD3DMetal))

                            Button(action: {
                                engine.setGraphicsBackend(for: game.id, useD3DMetal: false)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: !game.useD3DMetal ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(!game.useD3DMetal ? .blue : .secondary)
                                    Text("DXVK (Vulkan)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.portaGlass(cornerRadius: 8, isProminent: !game.useD3DMetal))
                        }
                    }

                    Divider()

                    // 2. Metal Performance HUD & Synchronization
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Runtime Overlays & Synchronization")
                            .font(.system(size: 13, weight: .semibold))

                        Toggle("Metal Performance HUD (FPS & GPU Telemetry)", isOn: Binding(
                            get: { game.enableHud },
                            set: { _ in engine.toggleHud(for: game.id) }
                        ))
                        .toggleStyle(.switch)

                        Toggle("Event Synchronization (Esync)", isOn: Binding(
                            get: { game.enableEsync },
                            set: { _ in engine.toggleEsync(for: game.id) }
                        ))
                        .toggleStyle(.switch)

                        Toggle("Fast Thread Synchronization (Fsync)", isOn: Binding(
                            get: { game.enableFsync },
                            set: { _ in engine.toggleFsync(for: game.id) }
                        ))
                        .toggleStyle(.switch)
                    }

                    Divider()

                    // 3. Prefix & Directory Shortcuts
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Container & Filesystem")
                            .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 8) {
                            Button(action: {
                                engine.openPrefixFolder(for: game)
                            }) {
                                Label("Open Prefix Folder", systemImage: "folder")
                            }
                            .buttonStyle(.portaGlass(cornerRadius: 8))

                            Button(action: {
                                engine.openGameFolder(for: game)
                            }) {
                                Label("Open Game Files", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.portaGlass(cornerRadius: 8))
                        }

                        if game.configUtilityPath != nil {
                            Button(action: {
                                engine.launchConfigUtility(for: game)
                            }) {
                                Label("Launch Configuration Utility", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.portaGlass(cornerRadius: 8))
                        }
                    }

                    Divider()

                    // 4. Library Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Library Management")
                            .font(.system(size: 13, weight: .semibold))

                        Button(action: {
                            engine.deleteImportedGame(game)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Game from Library")
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(.portaGlass(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 480)
    }
}
