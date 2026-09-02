import Foundation
import AppKit

public struct AppBundleGenerator {
    public static let shared = AppBundleGenerator()

    private let fileManager = FileManager.default

    public var defaultApplicationsFolder: URL {
        let home = fileManager.homeDirectoryForCurrentUser
        let appsDir = home.appendingPathComponent("Applications/Porta Games", isDirectory: true)
        try? fileManager.createDirectory(at: appsDir, withIntermediateDirectories: true)
        return appsDir
    }

    /// Generates a native macOS .app bundle for the specified GameItem
    @discardableResult
    public func generateBundle(for game: GameItem, destinationDir: URL? = nil) -> URL? {
        let targetDir = destinationDir ?? defaultApplicationsFolder
        let sanitizedName = game.title.replacingOccurrences(of: "/", with: "-")
                                      .replacingOccurrences(of: ":", with: "-")
                                      .trimmingCharacters(in: .whitespacesAndNewlines)
        let appBundleURL = targetDir.appendingPathComponent("\(sanitizedName).app", isDirectory: true)

        let contentsURL = appBundleURL.appendingPathComponent("Contents", isDirectory: true)
        let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)

        do {
            // 1. Create Bundle Directory Structure
            try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

            // 2. Generate Info.plist
            let slug = sanitizedName.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            let bundleId = "com.porta.game.\(slug)"
            
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleName</key>
                <string>\(game.title)</string>
                <key>CFBundleDisplayName</key>
                <string>\(game.title)</string>
                <key>CFBundleIdentifier</key>
                <string>\(bundleId)</string>
                <key>CFBundleVersion</key>
                <string>1.0</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0</string>
                <key>CFBundleExecutable</key>
                <string>launch</string>
                <key>CFBundleIconFile</key>
                <string>AppIcon</string>
                <key>CFBundlePackageType</key>
                <string>APPL</string>
                <key>LSApplicationCategoryType</key>
                <string>public.app-category.games</string>
                <key>NSHighResolutionCapable</key>
                <true/>
                <key>NSSupportsAutomaticGraphicsSwitching</key>
                <true/>
            </dict>
            </plist>
            """
            let plistURL = contentsURL.appendingPathComponent("Info.plist")
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)

            // 3. Generate Executable Launcher Script
            let homePath = fileManager.homeDirectoryForCurrentUser.path
            let steamAppPath = "\(homePath)/Applications/Sikarugir/Steam.app"
            let wineBin = "\(steamAppPath)/Contents/SharedSupport/wine/bin/wine"
            let winePrefix = "\(steamAppPath)/Contents/SharedSupport/prefix"
            let frameworksDir = "\(steamAppPath)/Contents/Frameworks"
            let wineLibDir = "\(steamAppPath)/Contents/SharedSupport/wine/lib"

            var launchCommand = ""
            if let appId = game.steamAppId, !appId.isEmpty {
                launchCommand = """
                export WINEPREFIX="\(winePrefix)"
                export DYLD_FALLBACK_LIBRARY_PATH="\(wineLibDir):\(frameworksDir)"
                export MTL_SHADER_VALIDATION=0

                # Launch via Steam Wrapper
                "\(wineBin)" "C:\\Program Files (x86)\\Steam\\Steam.exe" -applaunch \(appId)
                """
            } else if !game.executablePath.isEmpty {
                launchCommand = """
                export WINEPREFIX="\(winePrefix)"
                export DYLD_FALLBACK_LIBRARY_PATH="\(wineLibDir):\(frameworksDir)"
                export MTL_SHADER_VALIDATION=0

                "\(wineBin)" "\(game.executablePath)"
                """
            } else {
                launchCommand = """
                open "\(steamAppPath)"
                """
            }

            let scriptContent = """
            #!/bin/bash
            # Porta Native Game Launcher: \(game.title)
            \(launchCommand)
            """

            let launchURL = macOSURL.appendingPathComponent("launch")
            try scriptContent.write(to: launchURL, atomically: true, encoding: .utf8)

            // Mark script as executable (chmod +x)
            let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
            try fileManager.setAttributes(attributes, ofItemAtPath: launchURL.path)

            // 4. Generate App Icon
            createAppIcon(for: game, resourcesURL: resourcesURL)

            return appBundleURL
        } catch {
            print("[AppBundleGenerator] Failed to generate bundle for \(game.title): \(error)")
            return nil
        }
    }

    private func createAppIcon(for game: GameItem, resourcesURL: URL) {
        let iconURL = resourcesURL.appendingPathComponent("AppIcon.icns")
        if let localPath = game.localPosterPath ?? game.localHeroPath,
           let image = NSImage(contentsOfFile: localPath) {
            saveImageAsIcon(image, to: iconURL)
        }
    }

    private func saveImageAsIcon(_ image: NSImage, to destinationURL: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
        
        // Write standard png representation as AppIcon fallback
        try? pngData.write(to: destinationURL.deletingPathExtension().appendingPathExtension("png"))
    }
}
