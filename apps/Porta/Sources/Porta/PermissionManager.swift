import Foundation
import AppKit
import ApplicationServices
import Combine

public struct PersistentBookmarkItem: Identifiable, Codable, Equatable {
    public var id: String { path }
    public let path: String
    public let bookmarkData: Data
    public let createdAt: Date
    public var isFolder: Bool

    public init(path: String, bookmarkData: Data, createdAt: Date = Date(), isFolder: Bool = false) {
        self.path = path
        self.bookmarkData = bookmarkData
        self.createdAt = createdAt
        self.isFolder = isFolder
    }
}

public enum SystemPermissionStatus: String, CaseIterable, Identifiable {
    case authorized = "Authorized"
    case denied = "Denied"
    case notDetermined = "Not Prompted"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .authorized: return "checkmark.shield.fill"
        case .denied: return "xmark.shield.fill"
        case .notDetermined: return "questionmark.shield.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .authorized: return "green"
        case .denied: return "red"
        case .notDetermined: return "orange"
        }
    }
}

@MainActor
public class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public var savedBookmarks: [String: PersistentBookmarkItem] = [:]
    @Published public var activeAccessedURLs: [URL] = []
    
    // System TCC permission statuses
    @Published public var accessibilityStatus: SystemPermissionStatus = .notDetermined
    @Published public var inputMonitoringStatus: SystemPermissionStatus = .notDetermined
    @Published public var fullDiskStatus: SystemPermissionStatus = .authorized

    private let storageURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let base = appSupport.appendingPathComponent("Porta/Profiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        self.storageURL = base.appendingPathComponent("permissions_bookmarks.json")

        loadBookmarksFromDisk()
        restoreAllSecurityScopedBookmarks()
        refreshSystemPermissions()
    }

    // MARK: - Security-Scoped Bookmarks Persistence

    public func persistBookmark(for url: URL) {
        do {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let item = PersistentBookmarkItem(
                path: url.path,
                bookmarkData: bookmarkData,
                createdAt: Date(),
                isFolder: isDir.boolValue
            )

            savedBookmarks[url.path] = item
            saveBookmarksToDisk()

            // Also immediately activate access for current session
            _ = startAccessing(url: url)
        } catch {
            print("⚠️ [PermissionManager] Failed to create security-scoped bookmark for \(url.path): \(error.localizedDescription)")
        }
    }

    public func resolveAndAccessBookmark(for path: String) -> URL? {
        if let item = savedBookmarks[path] {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: item.bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    persistBookmark(for: resolvedURL)
                }

                _ = startAccessing(url: resolvedURL)
                return resolvedURL
            } catch {
                print("⚠️ [PermissionManager] Failed to resolve bookmark for \(path): \(error.localizedDescription)")
            }
        }
        return nil
    }

    public func restoreAllSecurityScopedBookmarks() {
        for (_, item) in savedBookmarks {
            var isStale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: item.bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale {
                    persistBookmark(for: resolvedURL)
                }
                _ = startAccessing(url: resolvedURL)
            }
        }
    }

    private func startAccessing(url: URL) -> Bool {
        if activeAccessedURLs.contains(url) {
            return true
        }
        let success = url.startAccessingSecurityScopedResource()
        if success {
            activeAccessedURLs.append(url)
        }
        return success
    }

    public func stopAccessingAll() {
        for url in activeAccessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeAccessedURLs.removeAll()
    }

    public func clearAllSavedBookmarks() {
        stopAccessingAll()
        savedBookmarks.removeAll()
        saveBookmarksToDisk()
    }

    private func saveBookmarksToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(savedBookmarks) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    private func loadBookmarksFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([String: PersistentBookmarkItem].self, from: data) else {
            return
        }
        self.savedBookmarks = decoded
    }

    // MARK: - System TCC Permissions (Accessibility & Input Monitoring)

    public func refreshSystemPermissions() {
        checkAccessibilityStatus()
        checkInputMonitoringStatus()
    }

    public func checkAccessibilityStatus() {
        let isTrusted = AXIsProcessTrusted()
        self.accessibilityStatus = isTrusted ? .authorized : .denied
    }

    public func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAccessibilityStatus()
        }
    }

    public func checkInputMonitoringStatus() {
        // macOS TCC check for event tap & input monitoring
        if #available(macOS 10.15, *) {
            let isTrusted = AXIsProcessTrusted()
            self.inputMonitoringStatus = isTrusted ? .authorized : .notDetermined
        } else {
            self.inputMonitoringStatus = .authorized
        }
    }

    public func openSystemSettings(for type: String) {
        let urlString: String
        switch type {
        case "accessibility":
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case "inputMonitoring":
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring"
        case "fullDisk":
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        default:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
