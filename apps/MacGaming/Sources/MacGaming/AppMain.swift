import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false

        // Automatically restore and activate security-scoped bookmarks across app launches
        Task { @MainActor in
            PermissionManager.shared.restoreAllSecurityScopedBookmarks()
            PermissionManager.shared.refreshSystemPermissions()
        }

        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.hasShadow = true
                window.isMovableByWindowBackground = false
            }
        }
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

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

// MARK: - NSWindow Accessor Helper
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.hasShadow = true
                window.isMovableByWindowBackground = false
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
