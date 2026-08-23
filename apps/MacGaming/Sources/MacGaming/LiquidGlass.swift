import SwiftUI
import AppKit

// =============================================================================
// MARK: - Native Apple Liquid Glass System
// =============================================================================

// MARK: - 1. Glass Shape & Material Options
public enum GlassShapeOption: Equatable, Sendable {
    case capsule
    case rect(cornerRadius: CGFloat)
    case circle
}

public struct GlassConfiguration: Equatable, Sendable {
    public var variant: GlassVariant
    public var tintColor: Color?
    public var isInteractive: Bool

    public init(variant: GlassVariant = .regular, tintColor: Color? = nil, isInteractive: Bool = false) {
        self.variant = variant
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    public static var regular: GlassConfiguration {
        GlassConfiguration(variant: .regular)
    }

    public static var clear: GlassConfiguration {
        GlassConfiguration(variant: .clear)
    }

    public static var automatic: GlassConfiguration {
        GlassConfiguration(variant: .automatic)
    }

    public func tint(_ color: Color?) -> GlassConfiguration {
        var copy = self
        copy.tintColor = color
        return copy
    }

    public func interactive(_ interactive: Bool = true) -> GlassConfiguration {
        var copy = self
        copy.isInteractive = interactive
        return copy
    }
}

// MARK: - 2. Native Glass Effect Container
public struct GlassEffectContainer<Content: View>: View {
    @Environment(\.liquidGlassConfiguration) private var config
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let spacing: CGFloat
    public let content: Content

    public init(spacing: CGFloat = LiquidGlassTokens.standardSpacing, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            ZStack {
                if config.enabled && !reduceTransparency {
                    Capsule()
                        .fill(Color.white.opacity(config.variant == .clear ? 0.08 : 0.14))
                        .background(.regularMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .shadow(color: Color.black.opacity(0.10), radius: 8, y: 3)
        )
    }
}

// MARK: - 3. Liquid Glass View Modifier
public typealias CompatibilityBadgeView = MGCompatibilityBadge
public typealias PlayButton = MGPlayButton

public struct LiquidGlassViewModifier: ViewModifier {
    @Environment(\.liquidGlassConfiguration) private var globalConfig
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let config: GlassConfiguration
    public let shape: GlassShapeOption

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    public init(config: GlassConfiguration = .regular, shape: GlassShapeOption = .capsule) {
        self.config = config
        self.shape = shape
    }

    public func body(content: Content) -> some View {
        content
            .background(contentShape)
            .scaleEffect((config.isInteractive && globalConfig.interactionResponse == .full) ? (isPressed ? LiquidGlassTokens.pressingScale : (isHovered ? LiquidGlassTokens.interactionScale : 1.0)) : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
            .animation(reduceMotion ? nil : .spring(response: 0.20, dampingFraction: 0.8), value: isPressed)
            .onHover { hovering in
                if config.isInteractive && globalConfig.interactionResponse != .off {
                    isHovered = hovering
                }
            }
    }

    @ViewBuilder
    private var contentShape: some View {
        switch shape {
        case .capsule:
            Capsule()
                .fill(glassFillColor)
                .background(materialBackground, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(strokeGradient, lineWidth: isHovered ? 1.1 : 0.8)
                )
                .shadow(color: Color.black.opacity(isHovered ? 0.14 : 0.08), radius: isHovered ? 8 : 4, y: 2)

        case .rect(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(glassFillColor)
                .background(materialBackground, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(strokeGradient, lineWidth: isHovered ? 1.1 : 0.8)
                )
                .shadow(color: Color.black.opacity(isHovered ? 0.14 : 0.08), radius: isHovered ? 8 : 4, y: 2)

        case .circle:
            Circle()
                .fill(glassFillColor)
                .background(materialBackground, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(strokeGradient, lineWidth: isHovered ? 1.1 : 0.8)
                )
                .shadow(color: Color.black.opacity(isHovered ? 0.14 : 0.08), radius: isHovered ? 8 : 4, y: 2)
        }
    }

    private var effectiveVariant: GlassVariant {
        if config.variant != .automatic { return config.variant }
        return globalConfig.variant == .clear ? .clear : .regular
    }

    private var glassFillColor: Color {
        let baseOpacity: Double = effectiveVariant == .clear ? 0.06 : 0.14
        if let tint = config.tintColor ?? globalConfig.accentTint {
            return tint.opacity(isHovered ? baseOpacity + 0.06 : baseOpacity)
        }
        return Color.white.opacity(isHovered ? baseOpacity + 0.05 : baseOpacity)
    }

    private var materialBackground: some ShapeStyle {
        effectiveVariant == .clear ? .ultraThinMaterial : .regularMaterial
    }

    private var strokeGradient: LinearGradient {
        let topOpacity = isHovered ? 0.65 : 0.40
        let bottomOpacity = isHovered ? 0.30 : 0.15
        return LinearGradient(
            stops: [
                .init(color: Color.white.opacity(topOpacity), location: 0.0),
                .init(color: Color.white.opacity(0.10), location: 0.5),
                .init(color: Color.white.opacity(bottomOpacity), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 4. Crystal Clear Sidebar Glass Modifier
public struct CrystalClearSidebarGlassModifier: ViewModifier {
    @Environment(\.liquidGlassConfiguration) private var config
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if config.enabled && !reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(config.variant == .clear ? 0.06 : 0.10))
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(0.50), location: 0.0),
                                                .init(color: Color.white.opacity(0.12), location: 0.4),
                                                .init(color: Color.white.opacity(0.25), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(NSColor.windowBackgroundColor))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 6)
    }
}

// MARK: - 5. Liquid Glass Button Styles
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

public extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var glass: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(isProminent: false)
    }

    static var glassProminent: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(isProminent: true)
    }
}

private struct GlassButtonView: View {
    @Environment(\.liquidGlassConfiguration) private var globalConfig
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let configuration: ButtonStyle.Configuration
    let isProminent: Bool
    let customTint: Color?

    @State private var isHovered: Bool = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isProminent {
                        let activeColor = customTint ?? globalConfig.accentTint ?? Color.blue
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [activeColor, activeColor.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.8)
                            )
                            .shadow(color: activeColor.opacity(0.35), radius: isHovered ? 6 : 3, y: 2)
                    } else if globalConfig.enabled && !reduceTransparency {
                        Capsule()
                            .fill(Color.white.opacity(isHovered ? 0.18 : 0.10))
                            .background(.regularMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(isHovered ? 0.60 : 0.35), location: 0.0),
                                                .init(color: Color.white.opacity(0.10), location: 0.5),
                                                .init(color: Color.white.opacity(isHovered ? 0.30 : 0.15), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: isHovered ? 5 : 2, y: 1.5)
                    } else {
                        Capsule()
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
            )
            .scaleEffect((globalConfig.interactionResponse == .full) ? (configuration.isPressed ? LiquidGlassTokens.pressingScale : (isHovered ? LiquidGlassTokens.interactionScale : 1.0)) : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.8), value: configuration.isPressed)
            .onHover { hovering in
                if globalConfig.interactionResponse != .off {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - 6. View Modifiers & Helpers
public extension View {
    func crystalClearSidebarGlass(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(CrystalClearSidebarGlassModifier(cornerRadius: cornerRadius))
    }

    func glassEffect(_ config: GlassConfiguration = .regular, in shape: GlassShapeOption = .capsule) -> some View {
        self.background(
            Color.clear
                .modifier(LiquidGlassViewModifier(config: config, shape: shape))
        )
    }

    func glassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }

    func glassEffectUnion(id: String, namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace, isSource: true)
    }
}
