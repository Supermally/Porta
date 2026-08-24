import Foundation
import AppKit
import SwiftUI
import CryptoKit

// MARK: - Forge High-Performance Persistent Data & Artwork Cache Service
public final class DataCacheService: @unchecked Sendable {
    public static let shared = DataCacheService()

    // MARK: - Memory Caches
    private let imageMemoryCache = NSCache<NSString, NSImage>()
    private let cacheQueue = DispatchQueue(label: "com.forge.cache.queue", qos: .utility)

    // MARK: - File System Paths
    private let appSupportCacheDir: URL
    private let artworkDiskCacheDir: URL
    private let discoveryCacheURL: URL

    private init() {
        // 1. Setup App Support Cache Folder
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportCacheDir = appSupport.appendingPathComponent("MacGaming/Cache", isDirectory: true)
        self.discoveryCacheURL = appSupportCacheDir.appendingPathComponent("discovery_cache.json")

        // 2. Setup Caches Directory for Artwork
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.artworkDiskCacheDir = cachesDir.appendingPathComponent("com.forge.artwork", isDirectory: true)

        try? fileManager.createDirectory(at: appSupportCacheDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: artworkDiskCacheDir, withIntermediateDirectories: true)

        // Memory cache limits (approx 120 images in memory max)
        imageMemoryCache.countLimit = 120
    }

    // MARK: - 1. Application & Game Discovery Snapshot Cache

    public struct DiscoveryCachePayload: Codable {
        public let timestamp: Date
        public let applications: [AppItem]
        public let games: [GameItem]

        public init(timestamp: Date = Date(), applications: [AppItem], games: [GameItem]) {
            self.timestamp = timestamp
            self.applications = applications
            self.games = games
        }
    }

    public func loadDiscoveryCache() -> DiscoveryCachePayload? {
        guard FileManager.default.fileExists(atPath: discoveryCacheURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: discoveryCacheURL)
            let payload = try JSONDecoder().decode(DiscoveryCachePayload.self, from: data)
            return payload
        } catch {
            return nil
        }
    }

    public func saveDiscoveryCache(applications: [AppItem], games: [GameItem]) {
        cacheQueue.async {
            let payload = DiscoveryCachePayload(applications: applications, games: games)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            if let data = try? encoder.encode(payload) {
                try? data.write(to: self.discoveryCacheURL, options: .atomic)
            }
        }
    }

    // MARK: - 2. Persistent Artwork Disk & Memory Caching Engine

    public func getCachedImage(for url: URL) -> NSImage? {
        let key = NSString(string: url.absoluteString)

        // Level 1: In-Memory Cache
        if let memImage = imageMemoryCache.object(forKey: key) {
            return memImage
        }

        // Level 2: On-Disk Cache
        let diskURL = diskCacheURL(for: url)
        if FileManager.default.fileExists(atPath: diskURL.path),
           let diskData = try? Data(contentsOf: diskURL),
           let diskImage = NSImage(data: diskData) {
            imageMemoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }

        return nil
    }

    public func cacheImage(_ image: NSImage, for url: URL) {
        let key = NSString(string: url.absoluteString)
        imageMemoryCache.setObject(image, forKey: key)

        cacheQueue.async {
            let diskURL = self.diskCacheURL(for: url)
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88]) {
                try? jpegData.write(to: diskURL, options: .atomic)
            }
        }
    }

    public func prefetchArtwork(urls: [URL]) {
        cacheQueue.async {
            for url in urls {
                if self.getCachedImage(for: url) == nil {
                    // Download and cache quietly in background
                    if let data = try? Data(contentsOf: url),
                       let image = NSImage(data: data) {
                        self.cacheImage(image, for: url)
                    }
                }
            }
        }
    }

    private func diskCacheURL(for url: URL) -> URL {
        let hashed = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hashed.compactMap { String(format: "%02x", $0) }.joined() + ".jpg"
        return artworkDiskCacheDir.appendingPathComponent(filename)
    }
}

// MARK: - Cached Async Image View Component
public struct CachedArtworkImageView: View {
    let url: URL?
    let contentMode: ContentMode
    let placeholder: AnyView

    @State private var loadedImage: NSImage? = nil

    public init(
        url: URL?,
        contentMode: ContentMode = .fill,
        placeholder: AnyView = AnyView(Color.clear)
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let img = loadedImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else { return }

        // Fast memory/disk cache check (0ms)
        if let cached = DataCacheService.shared.getCachedImage(for: url) {
            self.loadedImage = cached
            return
        }

        // Asynchronous background fetch
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let image = NSImage(data: data) {
                DataCacheService.shared.cacheImage(image, for: url)
                DispatchQueue.main.async {
                    self.loadedImage = image
                }
            }
        }
    }
}
