import SwiftUI

public struct RuntimesView: View {
    @ObservedObject var engine: EngineService
    @StateObject private var runtimeManager = RuntimeManager.shared
    @StateObject private var envManager = EnvironmentManager.shared
    @State private var showingNewEnvDialog: Bool = false
    @State private var newEnvName: String = ""
    @State private var newEnvDesc: String = ""

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Runtimes & Environments")
                        .font(.system(size: 24, weight: .bold))
                    Text("Manage Windows compatibility translation layers, Wine engines, and isolated environments.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Runtimes Section
                runtimesSection

                Divider()

                // Environments Section
                environmentsSection
            }
            .padding(32)
        }
        .sheet(isPresented: $showingNewEnvDialog) {
            newEnvironmentSheet
        }
    }

    // MARK: - Runtimes Section
    private var runtimesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Installed Runtimes")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: { runtimeManager.detectRuntimes() }) {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VStack(spacing: 12) {
                ForEach(runtimeManager.runtimes) { runtime in
                    HStack(spacing: 16) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 24))
                            .foregroundColor(runtime.isDefault ? .blue : .purple)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(runtime.name)
                                    .font(.system(size: 14, weight: .bold))
                                if runtime.isDefault {
                                    Text("DEFAULT")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }

                            Text(runtime.version)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Label(runtime.architecture, systemImage: "macmini")
                                Label(runtime.metalSupportLevel, systemImage: "sparkles")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                        }

                        Spacer()

                        Menu {
                            Button {
                                if FileManager.default.fileExists(atPath: runtime.runnerPath) {
                                    NSWorkspace.shared.selectFile(runtime.runnerPath, inFileViewerRootedAtPath: "")
                                } else {
                                    let dir = (runtime.runnerPath as NSString).deletingLastPathComponent
                                    NSWorkspace.shared.open(URL(fileURLWithPath: dir))
                                }
                            } label: {
                                Label("Reveal Binaries in Finder", systemImage: "folder")
                            }

                            Button {
                                runtimeManager.defaultRuntimeId = runtime.id
                                runtimeManager.detectRuntimes()
                            } label: {
                                Label("Set as Default Engine", systemImage: "checkmark.circle")
                            }

                            Divider()

                            Button {
                                let prefix = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Porta/prefixes/default"
                                try? FileManager.default.createDirectory(atPath: prefix, withIntermediateDirectories: true)
                                NSWorkspace.shared.open(URL(fileURLWithPath: prefix))
                            } label: {
                                Label("Open Default Prefix", systemImage: "shippingbox")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Manage")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9))
                            }
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .padding(16)
                    .background(Color.secondary.opacity(0.04))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Environments Section
    private var environmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Windows Environments")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: { showingNewEnvDialog = true }) {
                    Image(systemName: "plus")
                    Text("New Environment")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            VStack(spacing: 12) {
                ForEach(envManager.environments) { env in
                    HStack(spacing: 16) {
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.indigo)
                            .frame(width: 44, height: 44)
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(env.name)
                                    .font(.system(size: 14, weight: .bold))
                                if env.isIsolated {
                                    Text("ISOLATED")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                            }

                            Text(env.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text(env.prefixPath)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.top, 2)
                        }

                        Spacer()

                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: env.prefixPath))
                        }) {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Open in Finder")
                    }
                    .padding(16)
                    .background(Color.secondary.opacity(0.04))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - New Environment Sheet
    private var newEnvironmentSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create Windows Environment")
                .font(.system(size: 16, weight: .bold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Environment Name")
                    .font(.system(size: 12, weight: .semibold))
                TextField("e.g. Creative Suite Environment", text: $newEnvName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Description (Optional)")
                    .font(.system(size: 12, weight: .semibold))
                TextField("e.g. Isolated for Photoshop & Plugins", text: $newEnvDesc)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Button("Cancel") { showingNewEnvDialog = false }
                Spacer()
                Button("Create") {
                    if !newEnvName.isEmpty {
                        _ = envManager.createEnvironment(name: newEnvName, description: newEnvDesc)
                        newEnvName = ""
                        newEnvDesc = ""
                        showingNewEnvDialog = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newEnvName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420, height: 260)
    }
}
