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
            // 1. Ultra-Deep Dark Space Canvas
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            // 2. High-Fidelity Ambient Aurora Glow
            auroraBackground
                .ignoresSafeArea()

            // 3. Central Liquid Glass Brand Composition
            VStack(spacing: 26) {
                ZStack {
                    // Stage A: Calm, Continuous Fluid Liquid Glass Metaball Goo
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        HighFidelityLiquidGlassBlob(time: time, isSettled: isSettled)
                    }
                    .opacity(showCrispIcon ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.42), value: showCrispIcon)

                    // Stage B: Crisp Settled Liquid Glass Icon Asset
                    crispGlassIcon
                        .opacity(showCrispIcon ? 1.0 : 0.0)
                        .scaleEffect(showCrispIcon ? 1.0 : 0.94)
                        .animation(.easeInOut(duration: 0.42), value: showCrispIcon)
                }
                .frame(width: 80, height: 80)

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

                // Stage D: Interactive Launch & Settle Controls
                if showEnterButton {
                    HStack(spacing: 14) {
                        // Settle / Wobble Action Button
                        Button(action: {
                            toggleSettleState()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isSettled ? "water.waves" : "square.dashed")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isSettled ? "Wobble Goo" : "Settle Icon")
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

    // MARK: - Settle & Wobble Orchestration
    private func toggleSettleState() {
        if isSettled {
            // Bloom back into fluid wobble
            withAnimation(.easeInOut(duration: 0.30)) {
                showCrispIcon = false
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                isSettled = false
            }
        } else {
            // Settle smoothly into icon
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                isSettled = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if self.isSettled {
                    withAnimation(.easeInOut(duration: 0.38)) {
                        self.showCrispIcon = true
                    }
                }
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
        withAnimation(.spring(response: 0.48, dampingFraction: 0.80)) {
            self.isSettled = true
        }

        // 2. Seamless crossfade to crisp glass icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.showCrispIcon = true
            }

            // 3. Cinematic handoff fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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

// MARK: - High-Fidelity Liquid Glass Metaball Blob Component (Calm & Organic Harmonic Waves)
private struct HighFidelityLiquidGlassBlob: View {
    let time: Double
    let isSettled: Bool

    var body: some View {
        let settleFactor: CGFloat = isSettled ? 0.0 : 1.0

        // Gentle, calm harmonic fluid physics (Low frequencies & soft amplitudes)
        let orb1X = CGFloat(sin(time * 1.25)) * 6.5 * settleFactor
        let orb1Y = CGFloat(cos(time * 0.95)) * 5.0 * settleFactor
        let orb1R: CGFloat = (isSettled ? 26 : (24 + CGFloat(sin(time * 1.40)) * 1.5 * settleFactor))

        let orb2X = CGFloat(cos(time * 1.45)) * 6.0 * settleFactor
        let orb2Y = CGFloat(sin(time * 1.15)) * 5.5 * settleFactor
        let orb2R: CGFloat = (isSettled ? 24 : (22 + CGFloat(cos(time * 1.30)) * 1.6 * settleFactor))

        let orb3X = CGFloat(sin(time * 1.65)) * 5.0 * settleFactor
        let orb3Y = CGFloat(-cos(time * 1.05)) * 6.0 * settleFactor
        let orb3R: CGFloat = (isSettled ? 22 : (20 + CGFloat(sin(time * 1.55)) * 1.4 * settleFactor))

        let orb4X = CGFloat(-cos(time * 1.35)) * 5.5 * settleFactor
        let orb4Y = CGFloat(-sin(time * 1.55)) * 4.5 * settleFactor
        let orb4R: CGFloat = (isSettled ? 20 : (18 + CGFloat(cos(time * 1.45)) * 1.2 * settleFactor))

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
                    x: center.x + orb1X * 0.4 - 10,
                    y: center.y + orb1Y * 0.4 - 14,
                    width: 22 + orb1R * 0.35,
                    height: 12 + orb1R * 0.25
                ))
                context.fill(
                    hlPath,
                    with: .linearGradient(
                        Gradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0.1), Color.clear]),
                        startPoint: CGPoint(x: center.x - 8, y: center.y - 16),
                        endPoint: CGPoint(x: center.x + 8, y: center.y)
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
        .frame(width: 140, height: 140)
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
