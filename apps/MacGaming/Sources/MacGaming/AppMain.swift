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
