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

    public let shape: GlassShapeOption
    public let spacing: CGFloat
    public let content: Content

    public init(shape: GlassShapeOption = .capsule, spacing: CGFloat = LiquidGlassTokens.standardSpacing, @ViewBuilder content: () -> Content) {
        self.shape = shape
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(containerBackground)
    }

    @ViewBuilder
    private var containerBackground: some View {
        switch shape {
        case .capsule:
            ZStack {
                if config.enabled && !reduceTransparency {
                    Capsule()
                        .fill(Color.white.opacity(config.variant == .clear ? 0.02 : 0.08))
                        .background(config.variant == .clear ? .ultraThinMaterial : .regularMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)

        case .rect(let radius):
            ZStack {
                if config.enabled && !reduceTransparency {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color.white.opacity(config.variant == .clear ? 0.02 : 0.08))
                        .background(config.variant == .clear ? .ultraThinMaterial : .regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                } else {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)

        case .circle:
            ZStack {
                if config.enabled && !reduceTransparency {
                    Circle()
                        .fill(Color.white.opacity(config.variant == .clear ? 0.02 : 0.08))
                        .background(config.variant == .clear ? .ultraThinMaterial : .regularMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                } else {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
        }
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
            .scaleEffect((config.isInteractive && globalConfig.interactionResponse == .full) ? (isPressed ? LiquidGlassTokens.pressingScale : 1.0) : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.20, dampingFraction: 0.8), value: isPressed)
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
                        .strokeBorder(strokeGradient, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)

        case .rect(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(glassFillColor)
                .background(materialBackground, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(strokeGradient, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)

        case .circle:
            Circle()
                .fill(glassFillColor)
                .background(materialBackground, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(strokeGradient, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        }
    }

    private var effectiveVariant: GlassVariant {
        if config.variant != .automatic { return config.variant }
        return globalConfig.variant == .clear ? .clear : .regular
    }

    private var glassFillColor: Color {
        let baseOpacity: Double = effectiveVariant == .clear ? 0.02 : 0.08
        if let tint = config.tintColor ?? globalConfig.accentTint {
            return tint.opacity(baseOpacity)
        }
        return Color.white.opacity(baseOpacity)
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

// MARK: - 7. Concentric Porta Glass Button Styles
public struct PortaGlassButtonStyle: ButtonStyle {
    public let cornerRadius: CGFloat
    public let isProminent: Bool
    public let tint: Color?

    public init(cornerRadius: CGFloat = 10, isProminent: Bool = false, tint: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        let activeTint = tint ?? Color.blue
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isProminent ? activeTint : Color.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
                    .background(
                        isProminent ? AnyShapeStyle(activeTint.opacity(0.85)) : AnyShapeStyle(.ultraThinMaterial),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        isProminent ? Color.white.opacity(0.60) : Color.white.opacity(0.35),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
            .foregroundColor(isProminent ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PortaGlassButtonStyle {
    static func portaGlass(cornerRadius: CGFloat = 10, isProminent: Bool = false, tint: Color? = nil) -> PortaGlassButtonStyle {
        PortaGlassButtonStyle(cornerRadius: cornerRadius, isProminent: isProminent, tint: tint)
    }
}

// MARK: - 8. Clear Liquid Glass Capsule Toggle Style
public struct PortaGlassToggleStyle: ToggleStyle {
    public let tint: Color

    public init(tint: Color = .blue) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.label
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                    configuration.isOn.toggle()
                }
            }) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    // Subordinate Clear Glass Capsule Track
                    Capsule()
                        .fill(
                            configuration.isOn
                                ? LinearGradient(colors: [tint, tint.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.primary.opacity(0.12), Color.primary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(configuration.isOn ? 0.65 : 0.40),
                                            Color.white.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.9
                                )
                        )
                        .frame(width: 46, height: 26)
                        .shadow(color: configuration.isOn ? tint.opacity(0.25) : Color.clear, radius: 4, y: 1.5)

                    // Optical Liquid Glass Lens Thumb
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 20, height: 20)

                        // Specular Highlight
                        VStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(0.80), location: 0.0),
                                            .init(color: Color.white.opacity(0.10), location: 0.5),
                                            .init(color: Color.clear, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 17, height: 9)
                                .padding(.top, 1)
                            Spacer()
                        }
                        .clipShape(Circle())

                        // 3D Rim
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.90), location: 0.0),
                                        .init(color: Color.white.opacity(0.30), location: 0.5),
                                        .init(color: Color.white.opacity(0.60), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                            .frame(width: 20, height: 20)
                    }
                    .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1.5)
                    .padding(3)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

public extension ToggleStyle where Self == PortaGlassToggleStyle {
    static var portaGlass: PortaGlassToggleStyle {
        PortaGlassToggleStyle()
    }
    static func portaGlass(tint: Color = .blue) -> PortaGlassToggleStyle {
        PortaGlassToggleStyle(tint: tint)
    }
}

// MARK: - 9. Clear Liquid Glass Slider
public struct PortaGlassSlider: View {
    @Binding public var value: Double
    public let range: ClosedRange<Double>
    public let step: Double?
    public let tint: Color

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0.0...1.0,
        step: Double? = nil,
        tint: Color = .blue
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let percentage = max(0, min(1, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
            let fillWidth = max(0, totalWidth * CGFloat(percentage))

            ZStack(alignment: .leading) {
                // Background Glass Track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .frame(height: 8)

                // Active Gradient Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.7), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 8)

                // Interactive Glass Knob
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1.5)
                    .frame(width: 18, height: 18)
                    .offset(x: max(0, min(totalWidth - 18, fillWidth - 9)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let locationX = max(0, min(totalWidth, gesture.location.x))
                        let newPercent = Double(locationX / totalWidth)
                        var calculated = range.lowerBound + (newPercent * (range.upperBound - range.lowerBound))
                        if let step = step {
                            calculated = (calculated / step).rounded() * step
                        }
                        self.value = max(range.lowerBound, min(range.upperBound, calculated))
                    }
            )
        }
        .frame(height: 20)
    }
}

// MARK: - 10. Liquid Glass Capsule Segment Lens Selector
public struct PortaGlassSegmentPicker<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    @Binding public var selection: T
    public let items: [T]
    @Namespace private var segmentNamespace
    @State private var pressedItem: T? = nil

    public init(selection: Binding<T>, items: [T]) {
        self._selection = selection
        self.items = items
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let isSelected = selection == item
                let isPressed = pressedItem == item

                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                        selection = item
                    }
                }) {
                    Text(item.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .frame(minWidth: 72)
                        .background {
                            if isSelected {
                                ZStack {
                                    // 1. Clear Optical Glass Lens Substrate
                                    Capsule()
                                        .fill(Color.white.opacity(isPressed ? 0.24 : 0.14))
                                        .background(.ultraThinMaterial, in: Capsule())

                                    // 2. Prismatic / Chromatic Specular Highlight Rim (Activates on press & hold like Apple's native design)
                                    if isPressed {
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.cyan.opacity(0.85),
                                                        Color.white.opacity(0.95),
                                                        Color.purple.opacity(0.80),
                                                        Color.pink.opacity(0.75),
                                                        Color.orange.opacity(0.80)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.2
                                            )
                                    } else {
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.65),
                                                        Color.white.opacity(0.15)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    }
                                }
                                .scaleEffect(isPressed ? 1.05 : 1.0)
                                .shadow(color: Color.black.opacity(isPressed ? 0.22 : 0.08), radius: isPressed ? 5 : 2, y: isPressed ? 2.5 : 1)
                                .matchedGeometryEffect(id: "selected_glass_lens", in: segmentNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if pressedItem != item {
                                withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                                    pressedItem = item
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                                pressedItem = nil
                            }
                        }
                )
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.04))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.30), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
        )
    }
}
