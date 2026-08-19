import SwiftUI
import AppKit

// MARK: - Ambient Chromatic Aura Canvas
/// Provides the ambient light, color, and optical depth for Liquid Glass elements to refract.
public struct LiquidGlassCanvas<Content: View>: View {
    @ObservedObject var engine: EngineService
    let content: Content

    @State private var animateAura: Bool = false

    public init(engine: EngineService, @ViewBuilder content: () -> Content) {
        self.engine = engine
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // 1. Deep Space Base
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            if engine.liquidGlassEnabled {
                // 2. Dynamic Chromatic Ambient Light Orbs (Refracted through glass)
                GeometryReader { geo in
                    ZStack {
                        // Top-Left Cyan/Sapphire Glow Orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.12, green: 0.58, blue: 0.98).opacity(0.28 * engine.liquidGlassIntensity),
                                        Color(red: 0.05, green: 0.35, blue: 0.85).opacity(0.12 * engine.liquidGlassIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: geo.size.width * 0.45
                                )
                            )
                            .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                            .offset(x: animateAura ? -60 : -100, y: animateAura ? -40 : -90)
                            .blur(radius: 60)

                        // Bottom-Right Violet/Magenta Glow Orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.20, blue: 0.95).opacity(0.25 * engine.liquidGlassIntensity),
                                        Color(red: 0.40, green: 0.10, blue: 0.70).opacity(0.10 * engine.liquidGlassIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: geo.size.width * 0.45
                                )
                            )
                            .frame(width: geo.size.width * 0.65, height: geo.size.width * 0.65)
                            .offset(x: animateAura ? geo.size.width * 0.35 : geo.size.width * 0.3, y: animateAura ? geo.size.height * 0.3 : geo.size.height * 0.35)
                            .blur(radius: 70)

                        // Center Subtle Emerald/Teal Shimmer Orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.85, blue: 0.75).opacity(0.12 * engine.liquidGlassIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: geo.size.width * 0.3
                                )
                            )
                            .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                            .offset(x: animateAura ? 50 : 0, y: animateAura ? 30 : -20)
                            .blur(radius: 50)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                            animateAura = true
                        }
                    }
                }
                .ignoresSafeArea()
            }

            // 3. Main Floating UI Layer
            content
        }
    }
}

// MARK: - Liquid Glass Bubble Modifier
public struct LiquidGlassBubbleModifier: ViewModifier {
    var cornerRadius: CGFloat
    var isEnabled: Bool
    var intensity: Double
    var isInteractive: Bool
    var tintColor: Color?
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
                        // 1. Ultra-Translucent Glass Material (Lets background aura bleed through)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.55 + (intensity * 0.25))

                        // 2. Liquid Glass Chromatic Fluid Tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (tintColor ?? Color.white).opacity(0.18 * intensity * (isHovered ? 1.6 : 1.0)),
                                        Color.white.opacity(0.04 * intensity),
                                        Color.clear,
                                        Color.black.opacity(0.15 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 3. Specular Curved Glass Highlight (The "Liquid Lens" Sheen)
                        VStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45 * intensity * (isHovered ? 1.5 : 1.0)),
                                    Color.white.opacity(0.12 * intensity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(18, cornerRadius * 1.2))
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

                        // 4. Razor-Sharp Liquid Specular Rim Bevel
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.95 * intensity * (isHovered ? 1.3 : 1.0)), location: 0.0),
                                        .init(color: Color.white.opacity(0.40 * intensity), location: 0.25),
                                        .init(color: Color.white.opacity(0.08 * intensity), location: 0.65),
                                        .init(color: Color.white.opacity(0.30 * intensity), location: 1.0)
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
                    color: (tintColor ?? Color.black).opacity(0.16 * intensity * (isHovered ? 1.4 : 1.0)),
                    radius: isHovered ? 18 : 10,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
                .scaleEffect(isPressed ? 0.98 : (isHovered && isInteractive ? 1.012 : 1.0))
                .animation(.smooth(duration: 0.22), value: isHovered)
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

// MARK: - View Extension for Liquid Glass
public extension View {
    func liquidGlassBubble(
        cornerRadius: CGFloat = 20,
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        self.modifier(LiquidGlassBubbleModifier(
            cornerRadius: cornerRadius,
            isEnabled: isEnabled,
            intensity: intensity,
            isInteractive: isInteractive,
            tintColor: tint
        ))
    }

    func liquidGlassPill(
        isEnabled: Bool = true,
        intensity: Double = 0.85,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        self.modifier(LiquidGlassBubbleModifier(
            cornerRadius: 100, // True capsule bubble
            isEnabled: isEnabled,
            intensity: intensity,
            isInteractive: isInteractive,
            tintColor: tint
        ))
    }
}

// MARK: - Native Liquid Glass Button Style (Capsule Glass Pod)
public struct LiquidGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var isEnabled: Bool = true
    var intensity: Double = 0.85
    var customTint: Color? = nil

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
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
                                        Color.white.opacity(0.55 * intensity),
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else if isEnabled {
                        // Translucent Glass Bubble Substrate
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.65)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35 * intensity),
                                        Color.white.opacity(0.06),
                                        Color.clear,
                                        Color.black.opacity(0.12 * intensity)
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
                                    .init(color: Color.white.opacity(isProminent ? 0.95 : 0.90 * intensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.35), location: 0.35),
                                    .init(color: Color.white.opacity(0.06), location: 0.75),
                                    .init(color: Color.white.opacity(0.35), location: 1.0)
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
                color: isProminent ? (customTint ?? Color.accentColor).opacity(0.4) : Color.black.opacity(0.14 * intensity),
                radius: configuration.isPressed ? 3 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
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
                        .fill(isHoveringDivider ? Color.accentColor.opacity(0.45) : Color.clear)
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
