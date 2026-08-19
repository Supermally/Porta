import SwiftUI
import AppKit

// =============================================================================
// MARK: - Apple Liquid Glass Native Framework Integration
// Based on Apple's Official Liquid Glass & Landmarks Architecture
// =============================================================================

// MARK: - 1. Liquid Glass Environment Configuration
private struct LiquidGlassEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

private struct LiquidGlassIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 0.85
}

public extension EnvironmentValues {
    var liquidGlassEnabled: Bool {
        get { self[LiquidGlassEnabledKey.self] }
        set { self[LiquidGlassEnabledKey.self] = newValue }
    }

    var liquidGlassIntensity: Double {
        get { self[LiquidGlassIntensityKey.self] }
        set { self[LiquidGlassIntensityKey.self] = newValue }
    }
}

// MARK: - 2. GlassEffectContainer
/// Combines multiple Liquid Glass views for optimal rendering performance,
/// shape blending, and morphing transitions across states.
public struct GlassEffectContainer<Content: View>: View {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    public let spacing: CGFloat
    public let content: Content

    public init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(6)
        .background(
            ZStack {
                if isGlassEnabled {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.65 + (glassIntensity * 0.25))

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.45 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.10 * glassIntensity), location: 0.5),
                                    .init(color: Color.white.opacity(0.25 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(isGlassEnabled ? 0.08 * glassIntensity : 0.04), radius: 6, x: 0, y: 3)
    }
}

public typealias GlassActionGroup = GlassEffectContainer

// MARK: - 3. Interactive Morphing Launch Glass Control
/// Implements Apple's coordinated morphing transitions using @Namespace and matchedGeometry.
/// Morphs fluidly from [ ▶ Play | Benchmark | Troubleshoot ] into a unified live session monitor.
public struct MorphingLaunchGlassControl: View {
    @ObservedObject var engine: EngineService
    let game: GameItem
    let onShowTroubleshoot: () -> Void
    var namespace: Namespace.ID

    public init(engine: EngineService, game: GameItem, onShowTroubleshoot: @escaping () -> Void, namespace: Namespace.ID) {
        self.engine = engine
        self.game = game
        self.onShowTroubleshoot = onShowTroubleshoot
        self.namespace = namespace
    }

    public var body: some View {
        Group {
            if engine.isGameModeActive {
                // Active Session State: Morphed Live Status Capsule
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.8), radius: 4)

                        Text("Running in D3DMetal Sandbox")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.leading, 6)

                    Divider()
                        .frame(height: 14)
                        .opacity(0.3)

                    Button {
                        engine.runBenchmark(for: game)
                    } label: {
                        Label("HUD", systemImage: "gauge.with.needle")
                    }
                    .buttonStyle(.plain)
                    .font(.caption)

                    Button {
                        engine.stopGame()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Stop")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isProminent: true, customTint: .red))
                    .matchedGeometryEffect(id: "primaryAction", in: namespace)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: Color.green.opacity(0.2), radius: 8, y: 3)
            } else {
                // Idle State: Prominent Play Button + Action Group
                HStack(spacing: 12) {
                    PlayButton(isPlaying: false) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            engine.launchGame(game)
                        }
                    }
                    .matchedGeometryEffect(id: "primaryAction", in: namespace)

                    GlassEffectContainer(spacing: 8) {
                        Button {
                            engine.runBenchmark(for: game)
                        } label: {
                            Label("Benchmark", systemImage: "gauge.with.needle")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                        Divider()
                            .frame(height: 14)
                            .opacity(0.3)

                        Button {
                            engine.runTroubleshooter(for: game)
                            onShowTroubleshoot()
                        } label: {
                            Label("Troubleshoot", systemImage: "wrench.and.screwdriver")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                        if !game.installPath.isEmpty {
                            Divider()
                                .frame(height: 14)
                                .opacity(0.3)

                            Button {
                                NSWorkspace.shared.selectFile(game.executablePath.isEmpty ? game.installPath : game.executablePath, inFileViewerRootedAtPath: game.installPath)
                            } label: {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .help("Show game files in Finder")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 4. Compatibility Badge View (Semantic Restrained Glass)
public struct CompatibilityBadgeView: View {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    public let badge: CompatibilityBadge

    public init(_ badge: CompatibilityBadge) {
        self.badge = badge
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: badge.iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(badge.color)

            Text(badge.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            ZStack {
                if isGlassEnabled {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.70 + (glassIntensity * 0.25))

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.40 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.08 * glassIntensity), location: 0.5),
                                    .init(color: Color.white.opacity(0.20 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
        )
        .clipShape(Capsule())
    }
}

// MARK: - 5. Play Button (Signature Prominent Action)
public struct PlayButton: View {
    public let isPlaying: Bool
    public let action: () -> Void

    public init(isPlaying: Bool = false, action: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(isPlaying ? "Stop Session" : "Play")
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .buttonStyle(LiquidGlassButtonStyle(
            isProminent: true,
            customTint: isPlaying ? Color.red : Color.accentColor
        ))
        .fixedSize()
    }
}

// MARK: - 6. Liquid Glass Button Style (Prominent and Standard Glass)
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var isProminent: Bool
    public var customTint: Color?

    public init(isProminent: Bool = false, customTint: Color? = nil) {
        self.isProminent = isProminent
        self.customTint = customTint
    }

    public func makeBody(configuration: Configuration) -> some View {
        GlassButtonView(configuration: configuration, isProminent: isProminent, customTint: customTint)
    }
}

private struct GlassButtonView: View {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    let configuration: ButtonStyle.Configuration
    let isProminent: Bool
    let customTint: Color?

    @State private var isHovered: Bool = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 32)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent Liquid Glass Capsule
                        Capsule()
                            .fill((customTint ?? Color.accentColor).gradient)
                            .opacity(configuration.isPressed ? 0.85 : 1.0)

                        if isGlassEnabled {
                            // Top Specular Curved Sheen
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isHovered ? 0.55 * glassIntensity : 0.40 * glassIntensity),
                                            Color.white.opacity(0.06),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    } else if isGlassEnabled {
                        // Standard Translucent Liquid Glass
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(isHovered ? 0.95 : (0.65 + (glassIntensity * 0.25)))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.28 * glassIntensity : 0.14 * glassIntensity),
                                        Color.white.opacity(0.02),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Capsule()
                            .fill(Color(NSColor.controlColor))
                    }

                    // Refractive Specular Rim Bevel
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? (isHovered ? 1.0 : 0.85) : (isHovered ? 0.85 * glassIntensity : 0.50 * glassIntensity)), location: 0.0),
                                    .init(color: Color.white.opacity(0.20), location: 0.4),
                                    .init(color: Color.white.opacity(0.04), location: 0.75),
                                    .init(color: Color.white.opacity(isHovered ? 0.35 * glassIntensity : 0.15 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(Capsule())
            .shadow(
                color: isProminent ? (customTint ?? Color.accentColor).opacity(isHovered ? 0.40 : 0.20) : Color.black.opacity(isGlassEnabled ? 0.06 * glassIntensity : 0.02),
                radius: isHovered ? 6 : 3,
                x: 0,
                y: isHovered ? 2 : 1
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - 7. View Extensions
public extension View {
    /// Injects liquid glass configuration environment values
    func liquidGlassEnvironment(enabled: Bool, intensity: Double) -> some View {
        self
            .environment(\.liquidGlassEnabled, enabled)
            .environment(\.liquidGlassIntensity, intensity)
    }

    /// Applies the standard Liquid Glass button style
    func glassButton(isProminent: Bool = false, tint: Color? = nil) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(isProminent: isProminent, customTint: tint))
    }
}
