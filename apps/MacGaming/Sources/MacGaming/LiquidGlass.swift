import SwiftUI
import AppKit

// MARK: - Apple Liquid Glass Modifier & Optical Subsystem
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
                        // 1. Ambient Background Light Transmission
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        // 2. Chromatic Refraction & Ambient Tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12 * intensity * (isHovered ? 1.5 : 1.0)),
                                        Color.accentColor.opacity(0.04 * intensity),
                                        Color.clear,
                                        Color.black.opacity(0.15 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Top Curved Specular Gloss Reflection (Apple Glass Sheen)
                        VStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35 * intensity * (isHovered ? 1.4 : 1.0)),
                                    Color.white.opacity(0.08 * intensity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(16, cornerRadius * 1.5))
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
                                        .init(color: Color.white.opacity(0.85 * intensity * (isHovered ? 1.3 : 1.0)), location: 0.0),
                                        .init(color: Color.white.opacity(0.35 * intensity), location: 0.2),
                                        .init(color: Color.white.opacity(0.08 * intensity), location: 0.6),
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
                    color: Color.black.opacity(0.18 * intensity),
                    radius: isHovered ? 14 : 8,
                    x: 0,
                    y: isHovered ? 6 : 3
                )
                .scaleEffect(isPressed ? 0.985 : (isHovered && isInteractive ? 1.008 : 1.0))
                .animation(.smooth(duration: 0.2), value: isHovered)
                .animation(.smooth(duration: 0.12), value: isPressed)
                .onHover { hovering in
                    if isInteractive {
                        isHovered = hovering
                        if hovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
        }
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 14,
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

// MARK: - Native Apple Liquid Glass Button Style
public struct LiquidGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var isEnabled: Bool = true
    var intensity: Double = 0.85

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if isProminent {
                        // Vibrant Glass Accent Capsule
                        Capsule()
                            .fill(Color.accentColor.gradient)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.40 * intensity),
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
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.30 * intensity),
                                        Color.white.opacity(0.05),
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

                    // Specular Highlight Rim
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isProminent ? 0.9 : 0.85 * intensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.25), location: 0.4),
                                    .init(color: Color.white.opacity(0.05), location: 0.8),
                                    .init(color: Color.white.opacity(0.30), location: 1.0)
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
                color: isProminent ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.12 * intensity),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Sidebar Splitter Resize Hover Cursor Component
public struct SplitterResizeCursorModifier: ViewModifier {
    @State private var isHoveringDivider: Bool = false

    public func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(isHoveringDivider ? Color.accentColor.opacity(0.4) : Color.clear)
                        .frame(width: 6)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHoveringDivider = hovering
                            if hovering {
                                NSCursor.resizeLeftRight.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                }
            )
    }
}

public extension View {
    func resizeCursorOnTrailingEdge() -> some View {
        self.modifier(SplitterResizeCursorModifier())
    }
}
