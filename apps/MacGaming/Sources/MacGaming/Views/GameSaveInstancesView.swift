import SwiftUI
import AppKit

public struct GameSaveInstancesView: View {
    @ObservedObject var engine: EngineService
    let game: GameItem

    @State private var manifest: GameSaveManifest? = nil
    @State private var showingCreateSheet: Bool = false
    @State private var newCheckpointName: String = ""
    @State private var newCheckpointNote: String = ""
    @State private var instanceToRestore: GameSaveInstance? = nil
    @State private var showingRestoreAlert: Bool = false
    @State private var statusFeedback: String? = nil

    public init(engine: EngineService, game: GameItem) {
        self.engine = engine
        self.game = game
    }

    private func refreshManifest() {
        self.manifest = engine.loadSaveManifest(for: game)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header & Actions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Save States")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    Button {
                        newCheckpointName = "Checkpoint \( (manifest?.instances.count ?? 0) + 1 )"
                        newCheckpointNote = ""
                        showingCreateSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Checkpoint")
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                if let activeDir = manifest?.activeSaveDirectory ?? engine.detectSaveDirectory(for: game) {
                    HStack(spacing: 4) {
                        Text("Save Path:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button {
                            NSWorkspace.shared.selectFile(activeDir, inFileViewerRootedAtPath: activeDir)
                        } label: {
                            Text(activeDir)
                                .font(.system(size: 10, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                } else {
                    Text("No active save path discovered yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let feedback = statusFeedback {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
                .transition(.opacity)
            }

            // Instances List
            let instances = manifest?.instances ?? []
            if instances.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No Saved Checkpoints Yet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Create snapshots of your game progress before risky mods or bosses.")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            } else {
                VStack(spacing: 8) {
                    ForEach(instances) { instance in
                        HStack(alignment: .center, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(instance.isAutoSave ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                    .frame(width: 30, height: 30)
                                Image(systemName: instance.isAutoSave ? "shield.fill" : "bookmark.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(instance.isAutoSave ? .orange : .blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(instance.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)

                                    if instance.isAutoSave {
                                        Text("AUTO")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .cornerRadius(3)
                                    }
                                }

                                if !instance.note.isEmpty {
                                    Text(instance.note)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Text("\(instance.formattedDate) • \(instance.formattedSize)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Action buttons
                            HStack(spacing: 6) {
                                Button {
                                    instanceToRestore = instance
                                    showingRestoreAlert = true
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .help("Rollback active game save to this checkpoint")

                                Button {
                                    engine.revealSaveSnapshotInFinder(instance: instance)
                                } label: {
                                    Image(systemName: "folder")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                                .help("Reveal checkpoint directory in Finder")

                                Button {
                                    engine.deleteSaveSnapshot(game: game, instance: instance)
                                    refreshManifest()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                .help("Delete this checkpoint snapshot")
                            }
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
        .onAppear {
            refreshManifest()
        }
        .sheet(isPresented: $showingCreateSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Create Save Checkpoint")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Save a point-in-time snapshot of your current game progress for '\(game.title)'.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Checkpoint Name")
                        .font(.caption)
                        .fontWeight(.semibold)
                    TextField("e.g. Before Final Boss, Chapter 4 Start", text: $newCheckpointName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes / Description (Optional)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    TextField("e.g. Level 45, full inventory, right before entrance", text: $newCheckpointNote)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Button("Cancel") {
                        showingCreateSheet = false
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button("Save Checkpoint") {
                        if let inst = engine.createSaveSnapshot(for: game, name: newCheckpointName, note: newCheckpointNote) {
                            statusFeedback = "Created checkpoint '\(inst.name)' successfully."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                statusFeedback = nil
                            }
                        }
                        refreshManifest()
                        showingCreateSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .frame(width: 420)
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text("Restore Save Checkpoint?"),
                message: Text("Restoring '\(instanceToRestore?.name ?? "Checkpoint")' will overwrite your current active save data. A safety rollback backup will be taken automatically before restoring."),
                primaryButton: .destructive(Text("Restore Checkpoint")) {
                    if let inst = instanceToRestore {
                        let success = engine.restoreSaveSnapshot(game: game, instance: inst)
                        if success {
                            statusFeedback = "Restored '\(inst.name)'! Safety backup created."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                statusFeedback = nil
                            }
                        }
                        refreshManifest()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
