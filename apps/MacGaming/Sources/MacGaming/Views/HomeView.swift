import SwiftUI

public struct HomeView: View {
    @ObservedObject var engine: EngineService
    @StateObject private var discovery = ApplicationDiscoveryEngine.shared
    @StateObject private var presence = DiscordRichPresenceService.shared
    @State private var showingInstallSheet: Bool = false

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Header Welcome
                headerSection

                // Hero Resume Card (Quick Launch)
                heroResumeCard

                // Recent Applications Horizontal Shelf
                recentApplicationsShelf

                // Platform Activity & System Overview Grid
                HStack(alignment: .top, spacing: 20) {
                    activityStreamWidget
                        .frame(maxWidth: .infinity)

                    systemStatusCard
                        .frame(width: 280)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showingInstallSheet) {
            UniversalInstallationSheet(engine: engine)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Porta")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Windows Software Platform for Apple Silicon • Powered by Forge Engine")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()

            Button(action: { showingInstallSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Install Software")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    // MARK: - Hero Resume Card
    private var heroResumeCard: some View {
        let topApp = engine.universalApplications.first(where: { $0.category == .launchers }) ?? engine.universalApplications.first

        return ZStack(alignment: .bottomLeading) {
            // Background Artwork or Ambient Mesh
            if let topApp = topApp, let urlStr = topApp.headerImageUrl ?? topApp.iconUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } placeholder: {
                    heroAmbientBackground
                }
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.85), Color.black.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            } else {
                heroAmbientBackground
            }

            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.35))
                        .frame(width: 72, height: 72)
                    Image(systemName: topApp?.category.icon ?? "app.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTINUE SESSION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)

                    Text(topApp?.name ?? "Windows Steam")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(topApp?.publisher ?? "Valve Corporation • Wine 10 + D3DMetal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if let app = topApp {
                    Button(action: { engine.launchApplication(app) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Open")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(20)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 4)
    }

    private var heroAmbientBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.35), Color.indigo.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 140)
    }

    // MARK: - Recent Applications Shelf
    private var recentApplicationsShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Managed Applications")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: { engine.activeTab = .applications }) {
                    Text("View All (\(engine.universalApplications.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            if engine.universalApplications.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text("No applications discovered yet")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                    Spacer()
                }
                .background(Color.secondary.opacity(0.04))
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(engine.universalApplications.prefix(8)) { app in
                            HomeAppCardView(app: app) {
                                engine.selectedApplication = app
                                engine.launchApplication(app)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Stream Widget
    private var activityStreamWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("History") { engine.activeTab = .activity }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
            }

            VStack(spacing: 8) {
                ForEach(engine.activityEvents.prefix(4)) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.severity.icon)
                            .foregroundColor(event.severity.color)
                            .font(.system(size: 12))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.title)
                                .font(.system(size: 12, weight: .medium))
                            Text(event.details)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(event.formattedTime)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.04))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.04))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu.fill")
                    .foregroundColor(.purple)
                Text("Platform Subsystems")
                    .font(.system(size: 14, weight: .bold))
            }

            VStack(spacing: 8) {
                statusRow(title: "Architecture", value: "Apple Silicon (ARM64)")
                statusRow(title: "Translation", value: "Apple D3DMetal (Metal 3)")
                statusRow(title: "Active Runtime", value: "Wine 10 (WoW64)")
                statusRow(title: "Rich Presence", value: presence.isEnabled ? "Active" : "Disabled")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.04))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Home App Card Component
private struct HomeAppCardView: View {
    let app: AppItem
    let onLaunch: () -> Void

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onLaunch) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    if let urlStr = app.headerImageUrl ?? app.iconUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .aspectRatio(16/10, contentMode: .fill)
                                    .frame(width: 150, height: 94)
                                    .clipped()
                            default:
                                fallbackBanner
                            }
                        }
                        .cornerRadius(10)
                    } else {
                        fallbackBanner
                    }

                    if app.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                            .padding(6)
                    }
                }
                .frame(width: 150, height: 94)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(app.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isHovered ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.03))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isHovered
                            ? LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.10), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: isHovered ? Color.black.opacity(0.12) : Color.clear, radius: 8, y: 3)
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.interactiveSpring(response: 0.2)) { isPressed = false } }
        )
    }

    private var fallbackBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.indigo.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 94)

            Image(systemName: app.category.icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
        }
    }
}
