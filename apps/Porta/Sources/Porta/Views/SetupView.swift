import SwiftUI

public struct SetupView: View {
    @ObservedObject var setupManager: SetupManager
    @State private var showingTechnicalDetails: Bool = false

    public init(setupManager: SetupManager) {
        self.setupManager = setupManager
    }

    public var body: some View {
        ZStack {
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
            .frame(width: 480, height: 440)
            .padding(32)
        }
        .frame(minWidth: 540, minHeight: 500)
    }

    // MARK: - Screen 1: Welcome
    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "cube.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.blue.opacity(0.35), radius: 12, y: 4)

            VStack(spacing: 8) {
                Text("Welcome to Porta")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("A seamless, native environment for running Windows applications and games on Apple Silicon.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Text("Porta uses the Forge Engine with Apple D3DMetal translation to deliver high performance without virtual machines.")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    setupManager.startInstallation()
                }
            }) {
                Text("Get Started")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 140, height: 20)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Screen 2: Installing
    private var installingScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Preparing Forge Engine")
                    .font(.system(size: 20, weight: .bold))
                Text("Configuring compatibility components and runtime environments")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 15))
                    Text("Apple Silicon Hardware & Metal 3")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("Verified")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }


            }
            .padding(.vertical, 4)

            Divider()

            VStack(spacing: 8) {
                ProgressView(value: setupManager.overallProgress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text(setupManager.dependencyManager.activeTaskDescription.isEmpty ? "Configuring translation runtimes..." : setupManager.dependencyManager.activeTaskDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(setupManager.overallProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showingTechnicalDetails.toggle()
                    }
                }) {
                    Text(showingTechnicalDetails ? "Hide Technical Details" : "Show Details")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            
            if showingTechnicalDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(setupManager.dependencyManager.dependencies) { dep in
                            dependencyRow(dep)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
            }

        }
    }

    // MARK: - Screen 3: Complete
    private var completeScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            VStack(spacing: 6) {
                Text("Porta is Ready")
                    .font(.system(size: 24, weight: .bold))

                Text("Your Windows compatibility environment is configured.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Text("You can now install and run Windows applications, suites, and games.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    setupManager.finalizeSetup()
                }
            }) {
                Text("Enter Porta")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 140, height: 20)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Screen 4: Error
    private func errorScreen(message: String, details: String?) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            VStack(spacing: 6) {
                Text("Setup Incomplete")
                    .font(.system(size: 20, weight: .bold))

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let details = details {
                Text(details)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Button("Retry") {
                    setupManager.startInstallation()
                }
                .buttonStyle(.borderedProminent)

                Button("Skip Setup (Manual)") {
                    setupManager.finalizeSetup()
                }
                .buttonStyle(.bordered)
            }
        }
    }

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
            case .notInstalled, .outdated:
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.4))
                    .font(.system(size: 15))
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 15))
            }

            Text(dep.name)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text(dep.version)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}
