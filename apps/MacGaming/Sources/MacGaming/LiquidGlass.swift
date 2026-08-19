import SwiftUI
import AppKit

// =============================================================================
// MARK: - Apple Liquid Glass Native Design System
// High-Fidelity Refraction • 3D Specular Rim Bevels • Ambient Translucency
// Matches iOS 26 / macOS Tahoe Reference Optics
// =============================================================================

// MARK: - 1. Liquid Glass Environment Configuration
private struct LiquidGlassEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

private struct LiquidGlassIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 0.90
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

// MARK: - 2. Ambient Chromatic Background (For Liquid Glass Refraction)
/// Provides the luminous chromatic backdrop necessary for liquid glass to scatter and refract light
public struct AmbientChromaticBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Base Deep Canvas
            (colorScheme == .dark ? Color(red: 0.05, green: 0.08, blue: 0.13) : Color(red: 0.94, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            // Ambient Chromatic Orbs for Glass Refraction
            GeometryReader { proxy in
                ZStack {
                    // Top-Leading Cyan/Cobalt Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.45, blue: 0.95).opacity(0.18),
                                    Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.45
                            )
                        )
                        .frame(width: proxy.size.width * 0.8, height: proxy.size.width * 0.8)
                        .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.15)
                        .blur(radius: 60)

                    // Bottom-Trailing Indigo/Purple Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.20, blue: 0.85).opacity(0.15),
                                    Color(red: 0.15, green: 0.35, blue: 0.80).opacity(0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.40
                            )
                        )
                        .frame(width: proxy.size.width * 0.7, height: proxy.size.width * 0.7)
                        .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.85)
                        .blur(radius: 70)
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - 3. Liquid Glass Card Modifier
public struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    public let cornerRadius: CGFloat
    public let tintColor: Color?

    public init(cornerRadius: CGFloat = 16, tintColor: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isGlassEnabled {
                        // 1. Ultra-Thin Material Substrate
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.70 + (glassIntensity * 0.25))

                        // 2. Translucent Internal Specular Gradient
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: (tintColor ?? Color.white).opacity(0.16 * glassIntensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.04 * glassIntensity), location: 0.35),
                                        .init(color: Color.clear, location: 0.65),
                                        .init(color: Color.white.opacity(0.03 * glassIntensity), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Curved Top Specular Lens Flare (Apple 3D Glass)
                        VStack {
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.40 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.08 * glassIntensity), location: 0.4),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(14, cornerRadius * 0.8))
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                        // 4. Refractive 3D Glass Rim Bevel with Chromatic dispersion
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.90 * glassIntensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.35 * glassIntensity), location: 0.30),
                                        .init(color: Color.white.opacity(0.06 * glassIntensity), location: 0.65),
                                        .init(color: Color.white.opacity(0.30 * glassIntensity), location: 0.90),
                                        .init(color: Color.white.opacity(0.60 * glassIntensity), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(isGlassEnabled ? 0.08 * glassIntensity : 0.04), radius: 10, x: 0, y: 5)
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 16, tintColor: Color? = nil) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, tintColor: tintColor))
    }
}

// MARK: - 4. GlassEffectContainer (Apple Multi-View Blended Container)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack {
                if isGlassEnabled {
                    // 1. Ultra-Thin Material Substrate
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.70 + (glassIntensity * 0.25))

                    // 2. Translucent Internal Specular Sheen
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.25 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.04 * glassIntensity), location: 0.4),
                                    .init(color: Color.clear, location: 0.7),
                                    .init(color: Color.white.opacity(0.08 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 3. Top-Rim Convex Lens Reflection
                    VStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45 * glassIntensity),
                                        Color.white.opacity(0.08 * glassIntensity),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 14)
                        Spacer()
                    }
                    .clipShape(Capsule())

                    // 4. Refractive 3D Specular Rim
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.35 * glassIntensity), location: 0.35),
                                    .init(color: Color.white.opacity(0.08 * glassIntensity), location: 0.65),
                                    .init(color: Color.white.opacity(0.45 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.3
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(isGlassEnabled ? 0.10 * glassIntensity : 0.04), radius: 8, x: 0, y: 4)
    }
}

public typealias GlassActionGroup = GlassEffectContainer

// MARK: - 5. Interactive Morphing Launch Glass Control
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
                            .shadow(color: Color.green.opacity(0.9), radius: 5)

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
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            engine.stopGame()
                        }
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
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95), location: 0.0),
                                    .init(color: Color.white.opacity(0.3), location: 0.5),
                                    .init(color: Color.white.opacity(0.6), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.green.opacity(0.25), radius: 10, y: 4)
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

// MARK: - 6. Compatibility Badge View (Semantic Restrained Glass)
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
                                    .init(color: Color.white.opacity(0.85 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.20 * glassIntensity), location: 0.4),
                                    .init(color: Color.white.opacity(0.06 * glassIntensity), location: 0.7),
                                    .init(color: Color.white.opacity(0.40 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
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
    }
}

// MARK: - 7. Play Button (Signature Prominent Action)
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
            customTint: isPlaying ? Color.red : Color(red: 0.05, green: 0.48, blue: 0.98)
        ))
        .fixedSize()
    }
}

// MARK: - 8. Liquid Glass Button Style (Prominent and Standard Glass)
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
            .font(.system(size: 13, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(height: 34)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent Liquid Glass Capsule
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (customTint ?? Color(red: 0.05, green: 0.48, blue: 0.98)),
                                        (customTint ?? Color(red: 0.02, green: 0.35, blue: 0.85))
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(configuration.isPressed ? 0.85 : 1.0)

                        if isGlassEnabled {
                            // Top Specular Curved Lens Flare
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(isHovered ? 0.70 * glassIntensity : 0.50 * glassIntensity), location: 0.0),
                                            .init(color: Color.white.opacity(0.12 * glassIntensity), location: 0.45),
                                            .init(color: Color.clear, location: 1.0)
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
                                    stops: [
                                        .init(color: Color.white.opacity(isHovered ? 0.35 * glassIntensity : 0.20 * glassIntensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.04 * glassIntensity), location: 0.4),
                                        .init(color: Color.clear, location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        Capsule()
                            .fill(Color(NSColor.controlColor))
                    }

                    // Refractive Specular 3D Rim Bevel
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? (isHovered ? 1.0 : 0.95) : (isHovered ? 0.95 * glassIntensity : 0.75 * glassIntensity)), location: 0.0),
                                    .init(color: Color.white.opacity(0.35), location: 0.35),
                                    .init(color: Color.white.opacity(0.08), location: 0.65),
                                    .init(color: Color.white.opacity(isHovered ? 0.60 * glassIntensity : 0.40 * glassIntensity), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.3
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(Capsule())
            .shadow(
                color: isProminent ? (customTint ?? Color.accentColor).opacity(isHovered ? 0.50 : 0.30) : Color.black.opacity(isGlassEnabled ? 0.08 * glassIntensity : 0.02),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 3 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.025 : 1.0))
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - 9. View Extensions
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
