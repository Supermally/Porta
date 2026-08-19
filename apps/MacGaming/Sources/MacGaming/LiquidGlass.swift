import SwiftUI

// MARK: - Apple Liquid Glass Modifier & Styling
public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var isEnabled: Bool
    var intensity: Double
    var isInteractive: Bool
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    public func body(content: Content) -> some View {
        if !isEnabled {
            content
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(cornerRadius)
        } else {
            content
                .background(
                    ZStack {
                        // 1. Base Adaptive Translucent Material
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.85 + (intensity * 0.15))

                        // 2. Liquid Glass Chromatic Specular Tint
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18 * intensity * (isHovered ? 1.4 : 1.0)),
                                        Color.accentColor.opacity(0.04 * intensity),
                                        Color.clear,
                                        Color.black.opacity(0.08 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Specular Curved Glass Highlight Reflection
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.65 * intensity * (isHovered ? 1.3 : 1.0)),
                                        Color.white.opacity(0.20 * intensity),
                                        Color.white.opacity(0.05 * intensity),
                                        Color.white.opacity(0.30 * intensity)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.0
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(
                    color: Color.black.opacity(0.08 * intensity),
                    radius: isHovered ? 12 : 6,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
                .scaleEffect(isPressed ? 0.98 : (isHovered && isInteractive ? 1.01 : 1.0))
                .animation(.smooth(duration: 0.22), value: isHovered)
                .animation(.smooth(duration: 0.15), value: isPressed)
                .onHover { hovering in
                    if isInteractive {
                        isHovered = hovering
                    }
                }
        }
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 12,
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        isInteractive: Bool = false
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            isEnabled: isEnabled,
            intensity: intensity,
            isInteractive: isInteractive
        ))
    }
}

// MARK: - Native Liquid Glass Button Style
public struct LiquidGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var isEnabled: Bool = true
    var intensity: Double = 0.85

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.gradient)
                            .opacity(configuration.isPressed ? 0.85 : 1.0)
                    } else if isEnabled {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .opacity(0.9)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25 * intensity),
                                        Color.clear,
                                        Color.black.opacity(0.06 * intensity)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlColor))
                    }

                    // Liquid Glass Rim Highlight
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isProminent ? 0.5 : 0.6 * intensity),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.02 : 0.08), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
