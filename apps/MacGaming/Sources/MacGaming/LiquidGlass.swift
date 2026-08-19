import SwiftUI
import AppKit

// =============================================================================
// MARK: - Crystal Clear Apple Liquid Glass Design System
// In-App Layer Refraction • Sliding Content Underflow • 3D Specular Edges
// =============================================================================

// MARK: - 1. Liquid Glass Configuration Environment
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

// MARK: - 2. Native AppKit Visual Effect Blur (In-App Within-Window Glass)
public struct VisualEffectBlurView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - 3. Liquid Glass Style & Shape Specifications
public enum GlassShapeOption {
    case capsule
    case rect(cornerRadius: CGFloat)
    case circle
}

public struct GlassConfiguration {
    public var tintColor: Color?
    public var isInteractive: Bool

    public init(tintColor: Color? = nil, isInteractive: Bool = false) {
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    public static var regular: GlassConfiguration {
        GlassConfiguration()
    }

    public func tint(_ color: Color) -> GlassConfiguration {
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

// MARK: - 4. Crystal-Clear Sidebar Glass Modifier (In-App Refraction)
public struct CrystalClearSidebarGlassModifier: ViewModifier {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    public let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isGlassEnabled {
                        // 1. In-App Within-Window Visual Effect (Refracts Sliding Content Behind It)
                        VisualEffectBlurView(
                            material: .hudWindow,
                            blendingMode: .withinWindow,
                            state: .active
                        )
                        .opacity(0.85 + (glassIntensity * 0.15))

                        // 2. Optical Glass Clarity Substrate (Zero milky frosting)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.04 * glassIntensity))

                        // 3. Top Specular Convex Lens Highlight
                        VStack {
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.40 * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.06 * glassIntensity), location: 0.4),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 18)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                        // 4. Razor-Sharp 3D Specular Rim Bevel
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.95 * glassIntensity), location: 0.0),
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
                            .fill(Color(NSColor.windowBackgroundColor))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(isGlassEnabled ? 0.14 * glassIntensity : 0.04), radius: 14, x: 0, y: 6)
    }
}

// MARK: - 5. GlassEffectContainer (In-App Blended Container)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            ZStack {
                if isGlassEnabled {
                    VisualEffectBlurView(
                        material: .hudWindow,
                        blendingMode: .withinWindow,
                        state: .active
                    )
                    .opacity(0.85)

                    Capsule()
                        .fill(Color.white.opacity(0.05 * glassIntensity))

                    VStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.25 * glassIntensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.03 * glassIntensity), location: 0.5),
                                        .init(color: Color.clear, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 12)
                        Spacer()
                    }
                    .clipShape(Capsule())

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
                            lineWidth: 1.2
                        )
                } else {
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(isGlassEnabled ? 0.08 * glassIntensity : 0.03), radius: 6, x: 0, y: 3)
    }
}

public typealias GlassActionGroup = GlassEffectContainer

// MARK: - 6. Liquid Glass Modifier (Crystal Clear In-App Pane)
public struct LiquidGlassViewModifier: ViewModifier {
    @Environment(\.liquidGlassEnabled) private var isGlassEnabled
    @Environment(\.liquidGlassIntensity) private var glassIntensity

    public let config: GlassConfiguration
    public let shape: GlassShapeOption
    @State private var isHovered: Bool = false

    public init(config: GlassConfiguration = .regular, shape: GlassShapeOption = .capsule) {
        self.config = config
        self.shape = shape
    }

    public func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isGlassEnabled {
                        glassBackground
                    } else {
                        fallbackBackground
                    }
                }
            )
            .scaleEffect(config.isInteractive && isHovered ? 1.025 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .onHover { hovering in
                if config.isInteractive {
                    isHovered = hovering
                }
            }
    }

    @ViewBuilder
    private var glassBackground: some View {
        switch shape {
        case .capsule:
            ZStack {
                VisualEffectBlurView(
                    material: .hudWindow,
                    blendingMode: .withinWindow,
                    state: .active
                )
                .opacity(0.85)

                Capsule()
                    .fill(Color.white.opacity((isHovered ? 0.09 : 0.04) * glassIntensity))

                if let tint = config.tintColor {
                    Capsule()
                        .fill(tint.opacity(0.12 * glassIntensity))
                }

                VStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity((isHovered ? 0.35 : 0.22) * glassIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.04 * glassIntensity), location: 0.4),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 12)
                    Spacer()
                }
                .clipShape(Capsule())

                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity((isHovered ? 1.0 : 0.90) * glassIntensity), location: 0.0),
                                .init(color: Color.white.opacity(0.35 * glassIntensity), location: 0.35),
                                .init(color: Color.white.opacity(0.08 * glassIntensity), location: 0.65),
                                .init(color: Color.white.opacity(0.40 * glassIntensity), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.06 * glassIntensity), radius: isHovered ? 6 : 3, y: isHovered ? 2 : 1)

        case .rect(let radius):
            ZStack {
                VisualEffectBlurView(
                    material: .hudWindow,
                    blendingMode: .withinWindow,
                    state: .active
                )
                .opacity(0.85)

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white.opacity((isHovered ? 0.08 : 0.04) * glassIntensity))

                if let tint = config.tintColor {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(tint.opacity(0.10 * glassIntensity))
                }

                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity((isHovered ? 0.35 : 0.22) * glassIntensity), location: 0.0),
                            .init(color: Color.white.opacity(0.04 * glassIntensity), location: 0.4),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: max(14, radius * 0.8))
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity((isHovered ? 0.95 : 0.85) * glassIntensity), location: 0.0),
                                .init(color: Color.white.opacity(0.30 * glassIntensity), location: 0.30),
                                .init(color: Color.white.opacity(0.06 * glassIntensity), location: 0.65),
                                .init(color: Color.white.opacity(0.30 * glassIntensity), location: 0.90),
                                .init(color: Color.white.opacity(0.55 * glassIntensity), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06 * glassIntensity), radius: isHovered ? 8 : 4, y: isHovered ? 3 : 2)

        case .circle:
            ZStack {
                VisualEffectBlurView(
                    material: .hudWindow,
                    blendingMode: .withinWindow,
                    state: .active
                )
                .opacity(0.85)

                Circle()
                    .fill(Color.white.opacity((isHovered ? 0.10 : 0.05) * glassIntensity))

                if let tint = config.tintColor {
                    Circle()
                        .fill(tint.opacity(0.12 * glassIntensity))
                }

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity((isHovered ? 1.0 : 0.90) * glassIntensity), location: 0.0),
                                .init(color: Color.white.opacity(0.35 * glassIntensity), location: 0.35),
                                .init(color: Color.white.opacity(0.08 * glassIntensity), location: 0.65),
                                .init(color: Color.white.opacity(0.40 * glassIntensity), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.06 * glassIntensity), radius: isHovered ? 6 : 3, y: isHovered ? 2 : 1)
        }
    }

    @ViewBuilder
    private var fallbackBackground: some View {
        switch shape {
        case .capsule:
            Capsule().fill(Color(NSColor.controlBackgroundColor))
        case .rect(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color(NSColor.controlBackgroundColor))
        case .circle:
            Circle().fill(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - 7. View Extensions (Skill API Surface)
public extension View {
    /// Applies true in-app crystal clear liquid glass to a floating sidebar
    func crystalClearSidebarGlass(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(CrystalClearSidebarGlassModifier(cornerRadius: cornerRadius))
    }

    /// Applies Liquid Glass with configuration and shape
    func glassEffect(_ config: GlassConfiguration = .regular, in shape: GlassShapeOption = .capsule) -> some View {
        self.modifier(LiquidGlassViewModifier(config: config, shape: shape))
    }

    /// Shortcut for card glass
    func liquidGlassCard(cornerRadius: CGFloat = 16, tintColor: Color? = nil) -> some View {
        self.glassEffect(.regular.tint(tintColor ?? Color.clear), in: .rect(cornerRadius: cornerRadius))
    }

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

// MARK: - 8. Ambient Chromatic Background (For Liquid Glass Refraction)
public struct AmbientChromaticBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(red: 0.06, green: 0.09, blue: 0.14) : Color(red: 0.94, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.45, blue: 0.95).opacity(0.22),
                                    Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.10),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.45
                            )
                        )
                        .frame(width: proxy.size.width * 0.85, height: proxy.size.width * 0.85)
                        .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.20)
                        .blur(radius: 60)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.40, green: 0.20, blue: 0.90).opacity(0.18),
                                    Color(red: 0.15, green: 0.35, blue: 0.80).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: proxy.size.width * 0.40
                            )
                        )
                        .frame(width: proxy.size.width * 0.75, height: proxy.size.width * 0.75)
                        .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.85)
                        .blur(radius: 70)
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - 9. Morphing Launch Glass Control
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
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
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
                )
                .shadow(color: Color.green.opacity(0.25), radius: 10, y: 4)
            } else {
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

// MARK: - 10. Compatibility Badge View (Crystal Clear Semantic Glass)
public struct CompatibilityBadgeView: View {
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
        .glassEffect(.regular.tint(badge.color.opacity(0.25)), in: .capsule)
    }
}

// MARK: - 11. Play Button (Crystal Sapphire Glass Action)
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

// MARK: - 12. Liquid Glass Button Style (Crystal Clear Standard & Prominent Glass)
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
                        VisualEffectBlurView(
                            material: .hudWindow,
                            blendingMode: .withinWindow,
                            state: .active
                        )
                        .opacity(0.85)

                        Capsule()
                            .fill(Color.white.opacity((isHovered ? 0.12 : 0.06) * glassIntensity))

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
                color: isProminent ? (customTint ?? Color.accentColor).opacity(isHovered ? 0.50 : 0.30) : Color.black.opacity(isGlassEnabled ? 0.06 * glassIntensity : 0.02),
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
