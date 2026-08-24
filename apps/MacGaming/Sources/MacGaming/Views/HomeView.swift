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
                Text("Forge")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Windows Software Platform for Apple Silicon")
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
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.18), Color.indigo.opacity(0.24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.20), lineWidth: 1)
                )

            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.25))
                        .frame(width: 72, height: 72)
                    Image(systemName: topApp?.category.icon ?? "app.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTINUE SESSION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)

                    Text(topApp?.name ?? "Windows Steam")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text(topApp?.publisher ?? "Valve Corporation • Wine 10 + D3DMetal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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
                        ForEach(engine.universalApplications.prefix(6)) { app in
                            AppCardView(app: app) {
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
                    .background(Color.secondary.opacity(0.04))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.04))
        .cornerRadius(14)
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
        .background(Color.secondary.opacity(0.04))
        .cornerRadius(14)
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

// MARK: - App Card Component
private struct AppCardView: View {
    let app: AppItem
    let onLaunch: () -> Void

    var body: some View {
        Button(action: onLaunch) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 140, height: 90)

                    Image(systemName: app.category.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if app.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                            .padding(8)
                    }
                }

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
            .frame(width: 140)
        }
        .buttonStyle(.plain)
    }
}
