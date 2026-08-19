import SwiftUI
import AppKit

// =============================================================================
// MARK: - Mac Gaming Liquid Glass Design System
// Apple Native First • Restrained Glass for Interactive Controls • Configurable Optics
// =============================================================================

// MARK: - Environment Keys for Liquid Glass Configuration
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

// MARK: - 1. Play Button (Signature Prominent Action)
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

// MARK: - 2. Glass Action Group (GlassEffectContainer)
/// Groups multiple interactive glass controls into a unified glass cluster
public struct GlassActionGroup<Content: View>: View {
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
                        .opacity(0.60 + (glassIntensity * 0.30))

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

// MARK: - 3. Compatibility Badge View (Restrained Semantic Glass)
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

// MARK: - 4. Liquid Glass Button Style (Prominent and Standard Glass)
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

// MARK: - 5. View Extensions
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
