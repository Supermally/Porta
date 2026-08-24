import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false

        // Automatically restore and activate security-scoped bookmarks asynchronously
        Task.detached(priority: .utility) {
            await MainActor.run {
                PermissionManager.shared.restoreAllSecurityScopedBookmarks()
                PermissionManager.shared.refreshSystemPermissions()
            }
        }

        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                Self.configureWindow(window)
            }
        }
    }

    static func configureWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.minSize = CGSize(width: 800, height: 520)
        window.collectionBehavior.insert([.fullScreenPrimary, .managed])
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            PermissionManager.shared.stopAccessingAll()
        }
    }
}

@main
struct MacGamingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var engine = EngineService.shared

    var body: some Scene {
        WindowGroup {
            RootAppContainerView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // 1. File Menu Enhancements
            CommandGroup(replacing: .newItem) {
                Button("Import Game Folder…") {
                    engine.openNativeFilePicker(chooseFolder: true)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Import Windows Executable (.exe)…") {
                    engine.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Import Universal Application…") {
                    engine.openNativeFilePicker(isUniversalApp: true, chooseFolder: false)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Divider()

                Button("Rescan All Environments & Storefronts") {
                    engine.scanAllLaunchers()
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // 2. Launchers Menu
            CommandMenu("Launchers") {
                Section("Storefront Integration") {
                    Button("Open Steam (Wine 10)") {
                        engine.launchSteam()
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])

                    Button("Sync Steam Cloud & Library") {
                        engine.syncSteamLibrary()
                    }
                }

                Divider()

                Section("Filter Storefront View") {
                    ForEach(StorefrontFilter.allCases, id: \.self) { filter in
                        Button(filter.rawValue) {
                            engine.selectedStorefront = filter
                            engine.activeTab = .library
                        }
                    }
                }
            }

            // 3. View Menu
            CommandMenu("View") {
                Section("Layout Style") {
                    Button("Grid View") {
                        engine.libraryViewMode = .grid
                    }
                    .keyboardShortcut("1", modifiers: .command)

                    Button("List View") {
                        engine.libraryViewMode = .list
                    }
                    .keyboardShortcut("2", modifiers: .command)
                }

                Divider()

                Section("Navigation") {
                    Button("Library / Games") {
                        engine.activeTab = .library
                    }
                    .keyboardShortcut("g", modifiers: [.command, .shift])

                    Button("Universal Applications") {
                        engine.activeTab = .applications
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])

                    Button("Activity & Audit Logs") {
                        engine.activeTab = .activity
                    }

                    Button("Downloads & Updates") {
                        engine.activeTab = .downloads
                    }

                    Button("Mac Native Discover") {
                        engine.activeTab = .discover
                    }
                }

                Divider()

                Section("Compatibility Tiers") {
                    Button("Show All Games") {
                        engine.selectedFilter = nil
                    }

                    ForEach(CompatibilityBadge.allCases, id: \.self) { tier in
                        Button(tier.rawValue) {
                            engine.selectedFilter = tier
                        }
                    }
                }
            }

            // 4. Settings & Tools Menu
            CommandMenu("Settings") {
                Section("Configuration") {
                    Button("Preferences / Settings…") {
                        engine.activeTab = .settings
                    }
                    .keyboardShortcut(",", modifiers: .command)

                    Button("Graphics & D3DMetal Debug Lab…") {
                        engine.activeTab = .debugLab
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])

                    Button("Developer Console & Logs…") {
                        engine.activeTab = .console
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }

                Divider()

                Section("Developer Options") {
                    Button(engine.isDeveloperModeEnabled ? "Disable Developer Mode" : "Enable Developer Mode") {
                        engine.isDeveloperModeEnabled.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - Root App Container with Instant Launch Loading Transition
private struct RootAppContainerView: View {
    @State private var isLaunchLoading: Bool = true
    @State private var isMainContentReady: Bool = false

    var body: some View {
        ZStack {
            // Main interface warms up asynchronously in the background
            if isMainContentReady || !isLaunchLoading {
                MainContentView()
                    .zIndex(1)
            } else {
                Color(red: 0.03, green: 0.03, blue: 0.06)
                    .ignoresSafeArea()
                    .zIndex(1)
            }

            // Instant launch loading overlay that renders on frame 1 with zero main-thread blocking
            if isLaunchLoading {
                LaunchLoadingView {
                    withAnimation(.easeInOut(duration: 0.40)) {
                        isLaunchLoading = false
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.40), value: isLaunchLoading)
        .background(WindowAccessor())
        .onAppear {
            // Defer MainContentView instantiation slightly so LaunchLoadingView draws its very first frame instantly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                self.isMainContentReady = true
            }
        }
    }
}

// MARK: - NSWindow Accessor Helper
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                AppDelegate.configureWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
