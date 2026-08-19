import SwiftUI
import AppKit

// MARK: - Native AppKit Window Configurator (True Window Translucency)
public struct WindowTranslucencyConfigurator: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.hasShadow = true
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Native AppKit Visual Effect View
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material = .underWindowBackground
    public var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    public var state: NSVisualEffectView.State = .active

    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = state
        return visualEffectView
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Crystal-Clear Liquid Glass Card Modifier
public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var isEnabled: Bool
    var intensity: Double
    var tintColor: Color?

    public func body(content: Content) -> some View {
        if !isEnabled {
            content
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(cornerRadius)
        } else {
            content
                .background(
                    ZStack {
                        // 1. Crystal Translucent Ultra-Thin Material Substrate
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.85 + (intensity * 0.15))

                        // 2. Optical Glass Specular Tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (tintColor ?? Color.white).opacity(0.14 * intensity),
                                        Color.white.opacity(0.04 * intensity),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Top Specular Glass Curve Highlight
                        VStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35 * intensity),
                                    Color.white.opacity(0.05 * intensity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(14, cornerRadius * 1.1))
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: cornerRadius,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: cornerRadius
                                )
                            )
                            Spacer()
                        }

                        // 4. Razor-Sharp Specular Glass Rim Bevel
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.80 * intensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.25 * intensity), location: 0.35),
                                        .init(color: Color.white.opacity(0.06 * intensity), location: 0.70),
                                        .init(color: Color.white.opacity(0.30 * intensity), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.0
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(
                    color: Color.black.opacity(0.08 * intensity),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        }
    }
}

// MARK: - View Extension for Liquid Glass
public extension View {
    func liquidGlassBubble(
        cornerRadius: CGFloat = 18,
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        tint: Color? = nil
    ) -> some View {
        self.modifier(LiquidGlassCardModifier(
            cornerRadius: cornerRadius,
            isEnabled: isEnabled,
            intensity: intensity,
            tintColor: tint
        ))
    }

    func liquidGlassPill(
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        tint: Color? = nil
    ) -> some View {
        self.modifier(LiquidGlassCardModifier(
            cornerRadius: 100, // True capsule
            isEnabled: isEnabled,
            intensity: intensity,
            tintColor: tint
        ))
    }
}

// MARK: - Responsive Interactive Liquid Glass Button Style
public struct LiquidGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var isEnabled: Bool = true
    var intensity: Double = 0.85
    var customTint: Color? = nil

    public init(
        isProminent: Bool = false,
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        customTint: Color? = nil
    ) {
        self.isProminent = isProminent
        self.isEnabled = isEnabled
        self.intensity = intensity
        self.customTint = customTint
    }

    public func makeBody(configuration: Configuration) -> some View {
        LiquidGlassButtonBody(
            configuration: configuration,
            isProminent: isProminent,
            isEnabled: isEnabled,
            intensity: intensity,
            customTint: customTint
        )
    }
}

// Separate view struct so hover state is cleanly isolated to the individual button
private struct LiquidGlassButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let isProminent: Bool
    let isEnabled: Bool
    let intensity: Double
    let customTint: Color?

    @State private var isHovered: Bool = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 34)
            .background(
                ZStack {
                    if isProminent {
                        // Vibrant Glass Capsule with dynamic glow
                        Capsule()
                            .fill((customTint ?? Color.accentColor).gradient)
                            .opacity(configuration.isPressed ? 0.85 : (isHovered ? 1.0 : 0.92))

                        // Top Specular Glass Curve
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.60 * intensity : 0.45 * intensity),
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else if isEnabled {
                        // Translucent Glass Substrate
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(isHovered ? 0.95 : 0.80)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.35 * intensity : 0.18 * intensity),
                                        Color.white.opacity(0.04),
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

                    // Dynamic Razor Specular Highlight Rim
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? (isHovered ? 1.0 : 0.90) : (isHovered ? 0.90 * intensity : 0.65 * intensity)), location: 0.0),
                                    .init(color: Color.white.opacity(isHovered ? 0.40 : 0.22), location: 0.35),
                                    .init(color: Color.white.opacity(0.06), location: 0.75),
                                    .init(color: Color.white.opacity(isHovered ? 0.40 : 0.20), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: isHovered ? 1.4 : 1.0
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(Capsule())
            .shadow(
                color: isProminent ? (customTint ?? Color.accentColor).opacity(isHovered ? 0.50 : 0.30) : Color.white.opacity(isHovered ? 0.12 * intensity : 0.0),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 3 : 1
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.03 : 1.0))
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
