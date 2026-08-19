import SwiftUI
import AppKit

// MARK: - Native AppKit Visual Effect Glass Material
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

// MARK: - Liquid Glass Optical Modifier (Stateless & High-Performance)
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
                        // 1. Translucent Native AppKit Glass Substrate
                        VisualEffectView(material: .menu, blendingMode: .withinWindow)
                            .opacity(0.65 + (intensity * 0.25))

                        // 2. Chromatic Light Gradient
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (tintColor ?? Color.white).opacity(0.12 * intensity),
                                        Color.white.opacity(0.03 * intensity),
                                        Color.clear,
                                        Color.black.opacity(0.15 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Specular Curved Glass Highlight (Liquid Lens Sheen)
                        VStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35 * intensity),
                                    Color.white.opacity(0.08 * intensity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(16, cornerRadius * 1.2))
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
                                        .init(color: Color.white.opacity(0.85 * intensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.30 * intensity), location: 0.3),
                                        .init(color: Color.white.opacity(0.06 * intensity), location: 0.7),
                                        .init(color: Color.white.opacity(0.25 * intensity), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(
                    color: Color.black.opacity(0.14 * intensity),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
    }
}

// MARK: - View Extension for Liquid Glass
public extension View {
    func liquidGlassBubble(
        cornerRadius: CGFloat = 20,
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

// MARK: - Native Liquid Glass Button Style (Pure ButtonStyle)
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
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if isProminent {
                        // Vibrant Glass Capsule with Internal Glow
                        Capsule()
                            .fill((customTint ?? Color.accentColor).gradient)
                            .opacity(configuration.isPressed ? 0.85 : 1.0)

                        // Top Specular Glass Curve
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.50 * intensity),
                                        Color.white.opacity(0.10),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else if isEnabled {
                        // Translucent Glass Substrate
                        VisualEffectView(material: .menu, blendingMode: .withinWindow)
                            .opacity(0.7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28 * intensity),
                                        Color.white.opacity(0.04),
                                        Color.clear,
                                        Color.black.opacity(0.10 * intensity)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Capsule()
                            .fill(Color(NSColor.controlColor))
                    }

                    // Razor Specular Highlight Rim
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? 0.95 : 0.85 * intensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.30), location: 0.35),
                                    .init(color: Color.white.opacity(0.06), location: 0.75),
                                    .init(color: Color.white.opacity(0.30), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(Capsule())
            .shadow(
                color: isProminent ? (customTint ?? Color.accentColor).opacity(0.35) : Color.black.opacity(0.12 * intensity),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
