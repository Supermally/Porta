import SwiftUI

public struct ApplicationDetailView: View {
    @ObservedObject var engine: EngineService
    let app: AppItem
    let onClose: () -> Void

    @StateObject private var envManager = EnvironmentManager.shared
    @StateObject private var runtimeManager = RuntimeManager.shared

    @State private var isRunning: Bool = false
    @State private var useD3DMetal: Bool = true
    @State private var enableHud: Bool = false

    public init(engine: EngineService, app: AppItem, onClose: @escaping () -> Void) {
        self.engine = engine
        self.app = app
        self.onClose = onClose
        self._useD3DMetal = State(initialValue: app.useD3DMetal)
        self._enableHud = State(initialValue: app.enableHud)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { engine.toggleFavorite(for: app) }) {
                    Image(systemName: app.isFavorite ? "star.fill" : "star")
                        .foregroundColor(app.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // App Hero
                    appHeroSection

                    // Primary Action Button
                    Button(action: {
                        engine.launchApplication(app)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Open \(app.name)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.portaGlass(cornerRadius: 12, isProminent: true))

                    Divider()

                    // Runtime & Environment Info
                    runtimeSection

                    Divider()

                    // Graphics & Compatibility Settings
                    graphicsSection

                    Divider()

                    // Storage & Actions
                    storageAndActionsSection
                }
                .padding(20)
            }
        }
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.85))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.18), radius: 16, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - App Hero
    private var appHeroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let urlStr = app.headerImageUrl ?? app.iconUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } placeholder: {
                    heroPlaceholder
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            } else {
                heroPlaceholder
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(app.publisher)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(app.category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
        }
    }

    private var heroPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.indigo.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)

            Image(systemName: app.category.icon)
                .font(.system(size: 38))
                .foregroundColor(.blue)
        }
    }

    // MARK: - Runtime Section
    private var runtimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RUNTIME & ENVIRONMENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            infoRow(label: "Environment", value: envManager.getEnvironment(by: app.environmentId).name)
            infoRow(label: "Runtime Engine", value: runtimeManager.getRuntime(by: app.runtimeId).name)
            infoRow(label: "Provider", value: app.launcherProvider.displayName)
            infoRow(label: "Compatibility", value: app.compatibilityTier.rawValue)
        }
    }

    // MARK: - Graphics Section
    private var graphicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GRAPHICS & TRANSLATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            infoRow(label: "Target API", value: app.graphicsApi)

            Toggle(isOn: $useD3DMetal) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Apple D3DMetal")
                        .font(.system(size: 12, weight: .medium))
                    Text("DirectX 11/12 on Metal 3")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $enableHud) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Metal Performance HUD")
                        .font(.system(size: 12, weight: .medium))
                    Text("Display live FPS & GPU load")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    // MARK: - Storage & Actions Section
    private var storageAndActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STORAGE & ACTIONS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            infoRow(label: "Size on Disk", value: app.formattedSize)
            infoRow(label: "Last Used", value: app.formattedLastUsed)

            VStack(spacing: 6) {
                Button(action: { engine.revealApplicationInFinder(app) }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Reveal in Finder")
                        Spacer()
                    }
                    .font(.system(size: 12))
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                Button(action: {
                    let env = envManager.getEnvironment(by: app.environmentId)
                    NSWorkspace.shared.open(URL(fileURLWithPath: env.prefixPath))
                }) {
                    HStack {
                        Image(systemName: "externaldrive")
                        Text("Open Environment Prefix")
                        Spacer()
                    }
                    .font(.system(size: 12))
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                Button(role: .destructive, action: {
                    engine.removeApplication(app)
                    onClose()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove from Porta")
                        Spacer()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}
