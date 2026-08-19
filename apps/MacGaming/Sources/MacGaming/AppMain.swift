import SwiftUI
import AppKit

@main
struct MacGamingApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
