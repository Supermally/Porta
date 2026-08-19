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

// MARK: - Native Liquid Glass Optical Subsystem
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
                        // 1. Apple Ultra-Thin Translucent Glass Material
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.70 + (intensity * 0.25))

                        // 2. Chromatic Light Gradient (Luminous & Clean)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (tintColor ?? Color.white).opacity(0.16 * intensity),
                                        Color.white.opacity(0.04 * intensity),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Specular Curved Top Glass Sheen
                        VStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35 * intensity),
                                    Color.white.opacity(0.06 * intensity),
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

                        // 4. Razor Specular Glass Rim Bevel
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.75 * intensity), location: 0.0),
                                        .init(color: Color.white.opacity(0.25 * intensity), location: 0.3),
                                        .init(color: Color.white.opacity(0.05 * intensity), location: 0.7),
                                        .init(color: Color.white.opacity(0.20 * intensity), location: 1.0)
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
                    radius: 8,
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

// MARK: - Native Liquid Glass Button Style
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
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 34)
            .background(
                ZStack {
                    if isProminent {
                        // Vibrant Glass Capsule
                        Capsule()
                            .fill((customTint ?? Color.accentColor).gradient)
                            .opacity(configuration.isPressed ? 0.85 : 1.0)

                        // Top Specular Glass Curve
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45 * intensity),
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
                            .opacity(0.85)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.22 * intensity),
                                        Color.white.opacity(0.03),
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

                    // Razor Specular Highlight Rim
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? 0.90 : 0.75 * intensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.22), location: 0.35),
                                    .init(color: Color.white.opacity(0.05), location: 0.75),
                                    .init(color: Color.white.opacity(0.20), location: 1.0)
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
                color: isProminent ? (customTint ?? Color.accentColor).opacity(0.3) : Color.black.opacity(0.08 * intensity),
                radius: configuration.isPressed ? 2 : 5,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
