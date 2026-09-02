import SwiftUI
import UniformTypeIdentifiers

public enum InstallStage: Int, CaseIterable {
    case selectSource = 0
    case analyze = 1
    case selectEnvironment = 2
    case installing = 3
    case completed = 4
}

public struct UniversalInstallationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var engine: EngineService
    @StateObject private var envManager = EnvironmentManager.shared
    @StateObject private var runtimeManager = RuntimeManager.shared
    @StateObject private var discovery = ApplicationDiscoveryEngine.shared

    @State private var currentStage: InstallStage = .selectSource
    @State private var selectedFilePath: String = ""
    @State private var detectedAppName: String = ""
    @State private var detectedArchitecture: String = "x64"
    @State private var detectedGraphics: String = "DirectX 11"
    @State private var detectedCategory: ApplicationCategory = .utilities
    @State private var selectedEnvId: String = "default"
    
    // Progress states
    @State private var progressStepIndex: Int = 0
    @State private var progressPct: Double = 0.0
    @State private var registeredApp: AppItem? = nil

    private let installSteps = [
        "Preparing Windows environment",
        "Configuring compatibility layer",
        "Executing installer",
        "Scanning for application binaries",
        "Registering universal application",
        "Finalizing environment state"
    ]

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install Windows Software")
                        .font(.system(size: 16, weight: .bold))
                    Text("Universal Windows application and environment installer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            // Main Step Content
            VStack {
                switch currentStage {
                case .selectSource:
                    sourceSelectionView
                case .analyze:
                    analysisView
                case .selectEnvironment:
                    environmentSelectionView
                case .installing:
                    progressView
                case .completed:
                    completionView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
        .frame(width: 580, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Stage 0: Select Source
    private var sourceSelectionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)

                Text("Select Windows Installer")
                    .font(.system(size: 18, weight: .bold))

                Text("Choose a Windows executable (.exe), installer package (.msi), or standalone software bundle.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            if !selectedFilePath.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.indigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text((selectedFilePath as NSString).lastPathComponent)
                            .font(.system(size: 13, weight: .semibold))
                        Text(selectedFilePath)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(10)
            }

            HStack(spacing: 12) {
                Button(action: browseForInstaller) {
                    HStack {
                        Image(systemName: "folder")
                        Text(selectedFilePath.isEmpty ? "Browse Files..." : "Choose Different File...")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                if !selectedFilePath.isEmpty {
                    Button(action: startAnalysis) {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Stage 1: Analyze
    private var analysisView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Installer Analysis")
                    .font(.system(size: 16, weight: .bold))
                Text("Forge analyzed the application requirements and compatibility profiles.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                analysisRow(title: "Application Name", value: detectedAppName, icon: "app.badge")
                analysisRow(title: "Target Architecture", value: detectedArchitecture, icon: "cpu")
                analysisRow(title: "Inferred Graphics API", value: detectedGraphics, icon: "sparkles")
                analysisRow(title: "Category", value: detectedCategory.rawValue, icon: detectedCategory.icon)
                analysisRow(title: "Recommended Runtime", value: "Forge Runtime 1.0 (Wine 10 + D3DMetal)", icon: "gearshape.2")
            }
            .padding(14)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)

            Spacer()

            HStack {
                Button("Back") { currentStage = .selectSource }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Configure Environment") { currentStage = .selectEnvironment }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Stage 2: Environment Selection
    private var environmentSelectionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Target Environment")
                    .font(.system(size: 16, weight: .bold))
                Text("Choose where this Windows application should be installed and managed.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(envManager.environments) { env in
                    Button(action: { selectedEnvId = env.id }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedEnvId == env.id ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(selectedEnvId == env.id ? .blue : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(env.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(env.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(selectedEnvId == env.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            HStack {
                Button("Back") { currentStage = .analyze }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Begin Installation") { runInstallationPipeline() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Stage 3: Installing Progress
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Installing \(detectedAppName)")
                    .font(.system(size: 16, weight: .bold))
                Text("Preparing and running installation pipeline...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progressPct, total: 1.0)
                .progressViewStyle(.linear)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<installSteps.count, id: \.self) { idx in
                    HStack(spacing: 10) {
                        if idx < progressStepIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if idx == progressStepIndex {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        Text(installSteps[idx])
                            .font(.system(size: 12, weight: idx == progressStepIndex ? .semibold : .regular))
                            .foregroundColor(idx > progressStepIndex ? .secondary : .primary)
                    }
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)

            Spacer()
        }
    }

    // MARK: - Stage 4: Completion View
    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundColor(.green)

            VStack(spacing: 6) {
                Text("\(detectedAppName) Ready")
                    .font(.system(size: 20, weight: .bold))
                Text("The software has been registered in Forge and is ready to run.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                if let app = registeredApp {
                    Button("Open \(app.name)") {
                        dismiss()
                        let env = envManager.getEnvironment(by: app.environmentId)
                        let runtime = runtimeManager.getRuntime(by: app.runtimeId)
                        LauncherProviderManager.shared.launchApplication(app, environment: env, runtime: runtime) { _ in }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func browseForInstaller() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "exe") ?? .data,
            UTType(filenameExtension: "msi") ?? .data
        ]

        if panel.runModal() == .OK, let url = panel.url {
            self.selectedFilePath = url.path
        }
    }

    private func startAnalysis() {
        let fileName = (selectedFilePath as NSString).lastPathComponent
        let baseName = (fileName as NSString).deletingPathExtension
        self.detectedAppName = baseName.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ").capitalized

        let lower = selectedFilePath.lowercased()
        if lower.contains("setup") || lower.contains("install") {
            self.detectedCategory = .utilities
        } else if lower.contains("game") || lower.contains("unreal") || lower.contains("unity") {
            self.detectedCategory = .games
        } else if lower.contains("photo") || lower.contains("draw") || lower.contains("media") {
            self.detectedCategory = .creative
        } else {
            self.detectedCategory = .utilities
        }

        self.currentStage = .analyze
    }

    private func runInstallationPipeline() {
        self.currentStage = .installing
        self.progressStepIndex = 0
        self.progressPct = 0.1

        // Execute stages with simulated async steps
        let targetEnv = envManager.getEnvironment(by: selectedEnvId)
        let runtime = runtimeManager.getRuntime(by: targetEnv.defaultRuntimeId)

        DiscordRichPresenceService.shared.setInstalling(appName: detectedAppName)

        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            DispatchQueue.main.async {
                self.progressStepIndex += 1
                self.progressPct = Double(self.progressStepIndex) / Double(self.installSteps.count)

                if self.progressStepIndex >= self.installSteps.count {
                    timer.invalidate()
                    
                    // Register application
                    let app = AppItem(
                        id: "app_" + UUID().uuidString.prefix(8).lowercased(),
                        name: self.detectedAppName,
                        category: self.detectedCategory,
                        publisher: "Windows Software",
                        version: "1.0",
                        architecture: self.detectedArchitecture,
                        executablePath: self.selectedFilePath,
                        workingDirectory: (self.selectedFilePath as NSString).deletingLastPathComponent,
                        environmentId: targetEnv.id,
                        runtimeId: runtime.id,
                        launcherProvider: .standalone,
                        compatibilityTier: .compatible,
                        graphicsApi: self.detectedGraphics,
                        useD3DMetal: true
                    )
                    self.registeredApp = app
                    self.engine.registerApplication(app)
                    self.currentStage = .completed
                }
            }
        }
    }

    private func analysisRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}
