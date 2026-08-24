import SwiftUI
import AppKit

// MARK: - Native AppKit Menu Bar Action Handlers
@MainActor
final class MenuActionsHandler: NSObject {
    static let shared = MenuActionsHandler()

    @objc func importGameFolder() {
        EngineService.shared.openNativeFilePicker(chooseFolder: true)
    }

    @objc func importGameExecutable() {
        EngineService.shared.openNativeFilePicker(isUniversalApp: false, chooseFolder: false)
    }

    @objc func importUniversalApp() {
        EngineService.shared.openNativeFilePicker(isUniversalApp: true, chooseFolder: false)
    }

    @objc func rescanEnvironments() {
        EngineService.shared.scanAllLaunchers()
    }

    @objc func launchSteam() {
        EngineService.shared.launchSteam()
    }

    @objc func syncSteam() {
        EngineService.shared.syncSteamLibrary()
    }

    @objc func setGridView() {
        EngineService.shared.libraryViewMode = .grid
    }

    @objc func setListView() {
        EngineService.shared.libraryViewMode = .list
    }

    @objc func openLibraryTab() {
        EngineService.shared.activeTab = .library
    }

    @objc func openApplicationsTab() {
        EngineService.shared.activeTab = .applications
    }

    @objc func openActivityTab() {
        EngineService.shared.activeTab = .activity
    }

    @objc func openDownloadsTab() {
        EngineService.shared.activeTab = .downloads
    }

    @objc func openDiscoverTab() {
        EngineService.shared.activeTab = .discover
    }

    @objc func openSettingsTab() {
        EngineService.shared.activeTab = .settings
    }

    @objc func openDebugLabTab() {
        EngineService.shared.activeTab = .debugLab
    }

    @objc func openConsoleTab() {
        EngineService.shared.activeTab = .console
    }

    @objc func toggleDeveloperMode() {
        EngineService.shared.isDeveloperModeEnabled.toggle()
    }
}

// MARK: - NSApplicationDelegate
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set regular activation policy and bring to front so the macOS system menu bar is fully clickable
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSWindow.allowsAutomaticWindowTabbing = false

        // Build complete AppKit main menu hierarchy
        buildNativeAppMenu()

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

    private func buildNativeAppMenu() {
        let mainMenu = NSMenu()

        // 1. App Menu (Porta)
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Porta")
        appMenu.addItem(withTitle: "About Porta", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        let pref = appMenu.addItem(withTitle: "Settings…", action: #selector(MenuActionsHandler.shared.openSettingsTab), keyEquivalent: ",")
        pref.target = MenuActionsHandler.shared
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Porta", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Porta", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let importFolder = fileMenu.addItem(withTitle: "Import Game Folder…", action: #selector(MenuActionsHandler.shared.importGameFolder), keyEquivalent: "o")
        importFolder.target = MenuActionsHandler.shared
        let importExe = fileMenu.addItem(withTitle: "Import Windows Executable (.exe)…", action: #selector(MenuActionsHandler.shared.importGameExecutable), keyEquivalent: "O")
        importExe.target = MenuActionsHandler.shared
        let importUniversal = fileMenu.addItem(withTitle: "Import Universal Application…", action: #selector(MenuActionsHandler.shared.importUniversalApp), keyEquivalent: "I")
        importUniversal.target = MenuActionsHandler.shared
        fileMenu.addItem(NSMenuItem.separator())
        let rescan = fileMenu.addItem(withTitle: "Rescan All Environments & Storefronts", action: #selector(MenuActionsHandler.shared.rescanEnvironments), keyEquivalent: "r")
        rescan.target = MenuActionsHandler.shared
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Launchers Menu
        let launchersMenuItem = NSMenuItem()
        let launchersMenu = NSMenu(title: "Launchers")
        let openSteam = launchersMenu.addItem(withTitle: "Open Steam (Wine 10)", action: #selector(MenuActionsHandler.shared.launchSteam), keyEquivalent: "1")
        openSteam.keyEquivalentModifierMask = [.command, .option]
        openSteam.target = MenuActionsHandler.shared
        let syncSteam = launchersMenu.addItem(withTitle: "Sync Steam Cloud & Library", action: #selector(MenuActionsHandler.shared.syncSteam), keyEquivalent: "")
        syncSteam.target = MenuActionsHandler.shared
        launchersMenuItem.submenu = launchersMenu
        mainMenu.addItem(launchersMenuItem)

        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let gridView = viewMenu.addItem(withTitle: "Grid View", action: #selector(MenuActionsHandler.shared.setGridView), keyEquivalent: "1")
        gridView.target = MenuActionsHandler.shared
        let listView = viewMenu.addItem(withTitle: "List View", action: #selector(MenuActionsHandler.shared.setListView), keyEquivalent: "2")
        listView.target = MenuActionsHandler.shared
        viewMenu.addItem(NSMenuItem.separator())
        let libTab = viewMenu.addItem(withTitle: "Library / Games", action: #selector(MenuActionsHandler.shared.openLibraryTab), keyEquivalent: "G")
        libTab.target = MenuActionsHandler.shared
        let appTab = viewMenu.addItem(withTitle: "Universal Applications", action: #selector(MenuActionsHandler.shared.openApplicationsTab), keyEquivalent: "A")
        appTab.target = MenuActionsHandler.shared
        let actTab = viewMenu.addItem(withTitle: "Activity & Audit Logs", action: #selector(MenuActionsHandler.shared.openActivityTab), keyEquivalent: "")
        actTab.target = MenuActionsHandler.shared
        let downTab = viewMenu.addItem(withTitle: "Downloads & Updates", action: #selector(MenuActionsHandler.shared.openDownloadsTab), keyEquivalent: "")
        downTab.target = MenuActionsHandler.shared
        let discTab = viewMenu.addItem(withTitle: "Mac Native Discover", action: #selector(MenuActionsHandler.shared.openDiscoverTab), keyEquivalent: "")
        discTab.target = MenuActionsHandler.shared
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 5. Settings Menu
        let settingsMenuItem = NSMenuItem()
        let settingsMenu = NSMenu(title: "Settings")
        let prefItem = settingsMenu.addItem(withTitle: "Preferences / Settings…", action: #selector(MenuActionsHandler.shared.openSettingsTab), keyEquivalent: ",")
        prefItem.target = MenuActionsHandler.shared
        let debugLab = settingsMenu.addItem(withTitle: "Graphics & D3DMetal Debug Lab…", action: #selector(MenuActionsHandler.shared.openDebugLabTab), keyEquivalent: "D")
        debugLab.target = MenuActionsHandler.shared
        let console = settingsMenu.addItem(withTitle: "Developer Console & Logs…", action: #selector(MenuActionsHandler.shared.openConsoleTab), keyEquivalent: "C")
        console.target = MenuActionsHandler.shared
        settingsMenu.addItem(NSMenuItem.separator())
        let devMode = settingsMenu.addItem(withTitle: "Toggle Developer Mode", action: #selector(MenuActionsHandler.shared.toggleDeveloperMode), keyEquivalent: "")
        devMode.target = MenuActionsHandler.shared
        settingsMenuItem.submenu = settingsMenu
        mainMenu.addItem(settingsMenuItem)

        // 6. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            PermissionManager.shared.stopAccessingAll()
        }
    }
}

@main
struct PortaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var engine = EngineService.shared

    var body: some Scene {
        WindowGroup {
            RootAppContainerView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
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
