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
        VStack(alignment: .leading, spacing: 16) {
            // Header & Actions
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Save States & Progress Vault")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    if let activeDir = manifest?.activeSaveDirectory ?? engine.detectSaveDirectory(for: game) {
                        HStack(spacing: 4) {
                            Text("Active Save Directory:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button {
                                NSWorkspace.shared.selectFile(activeDir, inFileViewerRootedAtPath: activeDir)
                            } label: {
                                Text(activeDir)
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Text("No active save path discovered yet. Will auto-create on first snapshot.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    newCheckpointName = "Checkpoint \( (manifest?.instances.count ?? 0) + 1 )"
                    newCheckpointNote = ""
                    showingCreateSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Checkpoint")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
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
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No save state checkpoints created yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Create point-in-time snapshots before boss fights, major decisions, or to preserve multiple playthroughs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)

                    Button {
                        newCheckpointName = "Initial Save State"
                        newCheckpointNote = "First playthrough milestone"
                        showingCreateSheet = true
                    } label: {
                        Text("Create First Checkpoint")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            } else {
                VStack(spacing: 10) {
                    ForEach(instances) { instance in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(instance.isAutoSave ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: instance.isAutoSave ? "shield.fill" : "bookmark.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(instance.isAutoSave ? .orange : .blue)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(instance.name)
                                        .font(.system(size: 13, weight: .semibold))

                                    if instance.isAutoSave {
                                        Text("AUTO BACKUP")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .cornerRadius(4)
                                    }
                                }

                                if !instance.note.isEmpty {
                                    Text(instance.note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                HStack(spacing: 10) {
                                    Text(instance.formattedDate)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text(instance.formattedSize)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text("\(instance.fileCount) files")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Action buttons
                            HStack(spacing: 8) {
                                Button {
                                    instanceToRestore = instance
                                    showingRestoreAlert = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Restore")
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .help("Rollback active game save to this checkpoint")

                                Button {
                                    engine.revealSaveSnapshotInFinder(instance: instance)
                                } label: {
                                    Image(systemName: "folder")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .help("Reveal checkpoint folder in Finder")

                                Button {
                                    engine.deleteSaveSnapshot(game: game, instance: instance)
                                    refreshManifest()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.bordered)
                                .help("Delete this save checkpoint")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
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
