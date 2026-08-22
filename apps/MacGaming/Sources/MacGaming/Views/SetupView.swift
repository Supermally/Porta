import SwiftUI

public struct SetupView: View {
    @ObservedObject var setupManager: SetupManager
    @State private var showingTechnicalDetails: Bool = false

    public init(setupManager: SetupManager) {
        self.setupManager = setupManager
    }

    public var body: some View {
        ZStack {
            // Subtle clean dark/light ambient background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                switch setupManager.currentStep {
                case .welcome:
                    welcomeScreen
                case .checking, .installing:
                    installingScreen
                case .complete:
                    completeScreen
                case .error(let message, let details):
                    errorScreen(message: message, details: details)
                }

                Spacer()
            }
            .frame(width: 480, height: 420)
            .padding(32)
        }
        .frame(minWidth: 540, minHeight: 480)
    }

    // MARK: - Screen 1: Welcome
    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("Mac Gaming")
                    .font(.system(size: 26, weight: .bold))

                Text("Let's get things ready.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text("Mac Gaming needs a few components to run Windows games seamlessly on macOS.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    setupManager.startInstallation()
                }
            }) {
                Text("Continue")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 140, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Screen 2: Installing
    private var installingScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mac Gaming")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Text("Preparing your gaming environment")
                    .font(.system(size: 20, weight: .bold))
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                // Application status (Host is running)
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 15))
                    Text("Application")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("Ready")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Dynamic dependencies checklist
                ForEach(setupManager.dependencyManager.dependencies) { dep in
                    dependencyRow(dep)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Progress bar and active status
            VStack(spacing: 8) {
                ProgressView(value: setupManager.overallProgress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text(currentStatusText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    if let activeDownload = activeDownloadDetails {
                        Text(activeDownload)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func dependencyRow(_ dep: DependencyItem) -> some View {
        HStack(spacing: 12) {
            switch dep.status {
            case .installed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 15))
            case .downloading, .installing, .verifying:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 15, height: 15)
            case .notInstalled:
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.6))
                    .font(.system(size: 15))
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 15))
            case .outdated:
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 15))
            }

            Text(dep.name)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text(statusLabel(for: dep.status))
                .font(.system(size: 11))
                .foregroundColor(statusColor(for: dep.status))
        }
    }

    private func statusLabel(for status: DependencyStatus) -> String {
        switch status {
        case .installed(let ver):
            return "Installed (\(ver))"
        case .downloading(let progress, _, _):
            return "Downloading (\(Int(progress * 100))%)"
        case .installing:
            return "Installing…"
        case .verifying:
            return "Verifying…"
        case .notInstalled:
            return "Waiting…"
        case .failed:
            return "Failed"
        case .outdated:
            return "Update Available"
        }
    }

    private func statusColor(for status: DependencyStatus) -> Color {
        switch status {
        case .installed: return .secondary
        case .downloading, .installing, .verifying: return .accentColor
        case .notInstalled: return .secondary.opacity(0.6)
        case .failed: return .red
        case .outdated: return .orange
        }
    }

    private var currentStatusText: String {
        if !setupManager.dependencyManager.activeTaskDescription.isEmpty {
            return setupManager.dependencyManager.activeTaskDescription
        }
        return "Installing…"
    }

    private var activeDownloadDetails: String? {
        for dep in setupManager.dependencyManager.dependencies {
            if case .downloading(_, let written, let total) = dep.status {
                let writtenMB = Double(written) / (1024 * 1024)
                let totalMB = Double(total) / (1024 * 1024)
                if total > 0 {
                    return String(format: "%.0f MB / %.0f MB", writtenMB, totalMB)
                } else {
                    return String(format: "%.0f MB", writtenMB)
                }
            }
        }
        return nil
    }

    // MARK: - Screen 3: Ready to Play
    private var completeScreen: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("You're ready to play.")
                    .font(.system(size: 24, weight: .bold))

                Text("Your Mac Gaming environment has been successfully configured.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Spacer().frame(height: 12)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    setupManager.finalizeSetup()
                }
            }) {
                Text("Continue to Library")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 170, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Error Screen
    private func errorScreen(message: String, details: String?) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            VStack(spacing: 6) {
                Text(message)
                    .font(.system(size: 20, weight: .bold))

                Text("Mac Gaming couldn't download or install one of its required components. Check your internet connection and try again.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            if let details = details, !details.isEmpty {
                DisclosureGroup("View Details", isExpanded: $showingTechnicalDetails) {
                    ScrollView {
                        Text(details)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 80)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(8)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 20)
            }

            HStack(spacing: 14) {
                Button("Try Again") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        setupManager.startInstallation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
    }
}
