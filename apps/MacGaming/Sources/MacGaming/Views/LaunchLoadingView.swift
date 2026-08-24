import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void

    // MARK: - Interactive & Sequence States
    @State private var isSettled: Bool = false
    @State private var showCrispIcon: Bool = false
    @State private var showWordmark: Bool = true
    @State private var showEnterButton: Bool = true
    @State private var isEntering: Bool = false
    @State private var isFadingOut: Bool = false
    @State private var auroraPulse: Bool = false
    @State private var isButtonPressed: Bool = false

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // 1. Ultra-Deep Dark Canvas
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            // 2. High-Fidelity Ambient Aurora Glow
            auroraBackground
                .ignoresSafeArea()

            // 3. Central Liquid Glass Brand Composition
            VStack(spacing: 24) {
                ZStack {
                    // Stage A: Continuous Fluid Liquid Glass Metaball Goo
                    if !showCrispIcon {
                        TimelineView(.animation) { timeline in
                            let time = timeline.date.timeIntervalSinceReferenceDate
                            HighFidelityLiquidGlassBlob(time: time, isSettled: isSettled)
                        }
                        .transition(.opacity)
                    }

                    // Stage B: Crisp Settled Liquid Glass Icon Asset
                    if showCrispIcon {
                        crispGlassIcon
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                }
                .frame(width: 90, height: 90)

                // Stage C: Brand Wordmark
                VStack(spacing: 4) {
                    Text("Forge")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                        .shadow(color: Color.blue.opacity(0.4), radius: 8, y: 2)

                    Text("Windows Software Platform")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                        .tracking(0.4)
                }
                .opacity(showWordmark ? 1.0 : 0.0)
                .offset(y: showWordmark ? 0 : 6)

                // Stage D: Interactive Launch Controls
                if showEnterButton {
                    HStack(spacing: 14) {
                        // Settle / Wobble Toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                                isSettled.toggle()
                                if !isSettled {
                                    showCrispIcon = false
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isSettled ? "water.waves" : "square.dashed")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isSettled ? "Wobble Goo" : "Settle Shape")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                                    .background(.ultraThinMaterial, in: Capsule())
                            )
                            .foregroundColor(.white.opacity(0.90))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        // Enter Forge Primary Button
                        Button(action: {
                            enterForge()
                        }) {
                            HStack(spacing: 8) {
                                if isEntering {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Text("Enter Forge")
                                        .font(.system(size: 13, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.15, green: 0.50, blue: 1.0), Color(red: 0.38, green: 0.20, blue: 0.95)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.55), radius: 12, y: 3)
                            )
                            .foregroundColor(.white)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.7), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .scaleEffect(isButtonPressed ? 0.96 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(isEntering)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in withAnimation(.interactiveSpring(response: 0.15)) { isButtonPressed = true } }
                                .onEnded { _ in withAnimation(.interactiveSpring(response: 0.15)) { isButtonPressed = false } }
                        )
                    }
                    .padding(.top, 12)
                }
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                auroraPulse = true
            }
        }
    }

    // MARK: - High-Fidelity Ambient Aurora
    private var auroraBackground: some View {
        ZStack {
            // Cool Blue Radial Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.12, green: 0.40, blue: 1.0).opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: auroraPulse ? -80 : 70, y: auroraPulse ? -60 : 80)

            // Radiant Violet / Magenta Flare
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.88, green: 0.22, blue: 0.65).opacity(0.26), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 250
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: auroraPulse ? 80 : -70, y: auroraPulse ? 70 : -50)

            // Pale Cyan Caustic Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.82, blue: 0.78).opacity(0.28), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 230
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: auroraPulse ? 40 : -50, y: auroraPulse ? -80 : 60)
        }
        .blur(radius: 60)
    }

    // MARK: - Crisp Settled Liquid Glass Icon Asset
    private var crispGlassIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.46, blue: 0.98), Color(red: 0.38, green: 0.18, blue: 0.94)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: Color.blue.opacity(0.65), radius: 18, y: 6)

            // Specular Rim Light Bevel Stroke
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.white.opacity(0.20), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 64, height: 64)

            // Inner Specular Glass Reflection
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.40), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 38, height: 16)
                        .padding(.top, 4)
                        .padding(.leading, 6)
                    Spacer()
                }
                Spacer()
            }
            .frame(width: 64, height: 64)
            .clipped()

            // Brand Icon Glyph
            Image(systemName: "cube.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.4), radius: 5, y: 2)
        }
    }

    // MARK: - Enter Forge Action (Settle -> Crossfade -> Fade to App)
    private func enterForge() {
        isEntering = true

        // 1. Settle fluid goo into icon shape
        withAnimation(.spring(response: 0.40, dampingFraction: 0.75)) {
            self.isSettled = true
        }

        // 2. Crossfade to crisp glass icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeInOut(duration: 0.22)) {
                self.showCrispIcon = true
            }

            // 3. Cinematic handoff fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.isFadingOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.onFinish()
                }
            }
        }
    }
}

// MARK: - High-Fidelity Liquid Glass Metaball Blob Component
private struct HighFidelityLiquidGlassBlob: View {
    let time: Double
    let isSettled: Bool

    var body: some View {
        let settleFactor: CGFloat = isSettled ? 0.0 : 1.0

        // Multi-frequency harmonic fluid physics
        let orb1X = CGFloat(sin(time * 2.6)) * 14.0 * settleFactor
        let orb1Y = CGFloat(cos(time * 2.1)) * 10.0 * settleFactor
        let orb1R: CGFloat = (isSettled ? 28 : (24 + CGFloat(sin(time * 3.0)) * 3.0 * settleFactor))

        let orb2X = CGFloat(cos(time * 3.1)) * 13.0 * settleFactor
        let orb2Y = CGFloat(sin(time * 2.5)) * 12.0 * settleFactor
        let orb2R: CGFloat = (isSettled ? 26 : (21 + CGFloat(cos(time * 2.8)) * 3.5 * settleFactor))

        let orb3X = CGFloat(sin(time * 3.7)) * 11.0 * settleFactor
        let orb3Y = CGFloat(-cos(time * 2.3)) * 13.0 * settleFactor
        let orb3R: CGFloat = (isSettled ? 24 : (18 + CGFloat(sin(time * 3.6)) * 3.0 * settleFactor))

        let orb4X = CGFloat(-cos(time * 2.9)) * 12.0 * settleFactor
        let orb4Y = CGFloat(-sin(time * 3.4)) * 9.0 * settleFactor
        let orb4R: CGFloat = (isSettled ? 22 : (16 + CGFloat(cos(time * 3.2)) * 2.5 * settleFactor))

        ZStack {
            // Layer 1: Ambient Drop Shadow & Caustic Glow
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: Color.blue.opacity(0.6)))
                context.addFilter(.blur(radius: 12))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + 4)
                    drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                }
            }
            .blur(radius: 10)

            // Layer 2: Main Liquid Glass Body (Smooth Anti-Aliased Alpha Threshold)
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 11))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                }
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                    }
                }
            )
            .overlay(
                // Rich Translucent Liquid Glass Shading Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.70, blue: 1.0),
                        Color(red: 0.18, green: 0.45, blue: 0.98),
                        Color(red: 0.45, green: 0.18, blue: 0.92),
                        Color(red: 0.10, green: 0.85, blue: 0.80)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        context.addFilter(.blur(radius: 11))
                        context.drawLayer { ctx in
                            let center = CGPoint(x: size.width / 2, y: size.height / 2)
                            drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                        }
                    }
                )
            )

            // Layer 3: Inner Glass Refraction & Specular Caustic Bead
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let hlPath = Path(ellipseIn: CGRect(
                    x: center.x + orb1X * 0.5 - 12,
                    y: center.y + orb1Y * 0.5 - 16,
                    width: 24 + orb1R * 0.4,
                    height: 14 + orb1R * 0.3
                ))
                context.fill(
                    hlPath,
                    with: .linearGradient(
                        Gradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0.1), Color.clear]),
                        startPoint: CGPoint(x: center.x - 10, y: center.y - 18),
                        endPoint: CGPoint(x: center.x + 10, y: center.y)
                    )
                )
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                    }
                }
            )

            // Layer 4: Anti-Aliased Specular Glass Rim Light Stroke
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 11))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                }
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                    }
                }
            )
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.65), Color.white.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        context.addFilter(.blur(radius: 11))
                        context.drawLayer { ctx in
                            let center = CGPoint(x: size.width / 2, y: size.height / 2)
                            drawOrbs(in: ctx, center: center, o1: (orb1X, orb1Y, orb1R), o2: (orb2X, orb2Y, orb2R), o3: (orb3X, orb3Y, orb3R), o4: (orb4X, orb4Y, orb4R))
                        }
                    }
                )
            )
            .opacity(0.35)
        }
        .frame(width: 150, height: 150)
    }

    private func drawOrbs(
        in context: GraphicsContext,
        center: CGPoint,
        o1: (CGFloat, CGFloat, CGFloat),
        o2: (CGFloat, CGFloat, CGFloat),
        o3: (CGFloat, CGFloat, CGFloat),
        o4: (CGFloat, CGFloat, CGFloat)
    ) {
        let p1 = Path(ellipseIn: CGRect(x: center.x + o1.0 - o1.2, y: center.y + o1.1 - o1.2, width: o1.2 * 2, height: o1.2 * 2))
        let p2 = Path(ellipseIn: CGRect(x: center.x + o2.0 - o2.2, y: center.y + o2.1 - o2.2, width: o2.2 * 2, height: o2.2 * 2))
        let p3 = Path(ellipseIn: CGRect(x: center.x + o3.0 - o3.2, y: center.y + o3.1 - o3.2, width: o3.2 * 2, height: o3.2 * 2))
        let p4 = Path(ellipseIn: CGRect(x: center.x + o4.0 - o4.2, y: center.y + o4.1 - o4.2, width: o4.2 * 2, height: o4.2 * 2))

        context.fill(p1, with: .color(.black))
        context.fill(p2, with: .color(.black))
        context.fill(p3, with: .color(.black))
        context.fill(p4, with: .color(.black))
    }
}
