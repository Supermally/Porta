import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void

    // MARK: - Interactive & Sequence States
    @State private var settleProgress: Double = 0.0 // 0.0 = full fluid wobble, 1.0 = fully settled icon squircle
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
                // Morphing Liquid Glass Tile
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    MorphingLiquidGlassTile(time: time, settleProgress: settleProgress)
                }
                .frame(width: 80, height: 80)

                // Brand Wordmark
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

                // Interactive Launch & Settle Controls
                if showEnterButton {
                    HStack(spacing: 14) {
                        // Settle / Wobble Toggle
                        Button(action: {
                            toggleMorph()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: settleProgress > 0.5 ? "water.waves" : "square.dashed")
                                    .font(.system(size: 11, weight: .bold))
                                Text(settleProgress > 0.5 ? "Wobble Goo" : "Morph to Icon")
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

    // MARK: - Morphing Orchestration
    private func toggleMorph() {
        if settleProgress > 0.5 {
            // Morph back from icon to fluid goo
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                settleProgress = 0.0
            }
        } else {
            // Morph smoothly from fluid goo into rounded-rect icon
            withAnimation(.spring(response: 0.60, dampingFraction: 0.80)) {
                settleProgress = 1.0
            }
        }
    }

    private func enterForge() {
        isEntering = true

        // 1. Morph smoothly into the icon shape
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            settleProgress = 1.0
        }

        // 2. Cinematic transition into main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.isFadingOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.onFinish()
            }
        }
    }

    // MARK: - Ambient Aurora Background
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
}

// MARK: - Morphing Liquid Glass Tile (Goo -> True Squircle Icon Morph)
private struct MorphingLiquidGlassTile: View {
    let time: Double
    let settleProgress: Double // 0.0 = fluid goo, 1.0 = settled rounded-rectangle squircle

    var body: some View {
        let p = CGFloat(settleProgress)
        let invP = 1.0 - p

        // Organic Harmonic Wobble Offsets (calm fluid physics)
        let w1X = CGFloat(sin(time * 1.25)) * 7.0
        let w1Y = CGFloat(cos(time * 0.95)) * 6.0

        let w2X = CGFloat(cos(time * 1.40)) * 6.5
        let w2Y = CGFloat(sin(time * 1.15)) * 6.0

        let w3X = CGFloat(sin(time * 1.60)) * 6.0
        let w3Y = CGFloat(-cos(time * 1.05)) * 6.5

        let w4X = CGFloat(-cos(time * 1.30)) * 6.0
        let w4Y = CGFloat(-sin(time * 1.50)) * 5.5

        // Morphing Corner Coordinates:
        // Top-Left Corner:
        let c1X = (-16.0 * p) + (w1X * invP)
        let c1Y = (-16.0 * p) + (w1Y * invP)
        let c1R = (17.5 * p) + (24.0 * invP)

        // Top-Right Corner:
        let c2X = (16.0 * p) + (w2X * invP)
        let c2Y = (-16.0 * p) + (w2Y * invP)
        let c2R = (17.5 * p) + (22.0 * invP)

        // Bottom-Right Corner:
        let c3X = (16.0 * p) + (w3X * invP)
        let c3Y = (16.0 * p) + (w3Y * invP)
        let c3R = (17.5 * p) + (20.0 * invP)

        // Bottom-Left Corner:
        let c4X = (-16.0 * p) + (w4X * invP)
        let c4Y = (16.0 * p) + (w4Y * invP)
        let c4R = (17.5 * p) + (18.0 * invP)

        // Center Core Bead (Maintains solid squircle body):
        let centerR = (22.0 * p) + (24.0 * invP)

        // Edge Fillers that blend corners into flat squircle sides as p -> 1.0:
        let edgeR = 15.0 * p

        ZStack {
            // Layer 1: Ambient Drop Shadow & Blue Caustic Glow
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: Color.blue.opacity(0.65)))
                context.addFilter(.blur(radius: 12))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + (4 * p) + (2 * invP))
                    drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                }
            }
            .blur(radius: 10)

            // Layer 2: Main Liquid Glass Body (Smooth Anti-Aliased Alpha Threshold)
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 11))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                }
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )
            .overlay(
                // Rich Translucent Liquid Glass Shading Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.70, blue: 1.0),
                        Color(red: 0.16, green: 0.46, blue: 0.98),
                        Color(red: 0.40, green: 0.16, blue: 0.94),
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
                            drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                        }
                    }
                )
            )

            // Layer 3: Inner Glass Refraction & Top-Left Specular Reflection
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let hlX = (center.x - 14 * p) + (c1X * 0.4 * invP)
                let hlY = (center.y - 14 * p) + (c1Y * 0.4 * invP)
                let hlW = (28.0 * p) + (22.0 * invP)
                let hlH = (14.0 * p) + (12.0 * invP)

                let hlPath = Path(roundedRect: CGRect(x: hlX, y: hlY, width: hlW, height: hlH), cornerRadius: 6)
                context.fill(
                    hlPath,
                    with: .linearGradient(
                        Gradient(colors: [Color.white.opacity(0.65), Color.white.opacity(0.12), Color.clear]),
                        startPoint: CGPoint(x: hlX, y: hlY),
                        endPoint: CGPoint(x: hlX + hlW * 0.8, y: hlY + hlH)
                    )
                )
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )

            // Layer 4: Specular Rim Light Bevel Stroke
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 11))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                }
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.75), Color.white.opacity(0.18), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        context.addFilter(.blur(radius: 11))
                        context.drawLayer { ctx in
                            let center = CGPoint(x: size.width / 2, y: size.height / 2)
                            drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                        }
                    }
                )
            )
            .opacity((0.35 * invP) + (0.80 * p))

            // Layer 5: Embedded Icon Glyph (Emerges from inside the liquid glass as p -> 1.0)
            Image(systemName: "cube.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.40), radius: 5, y: 2)
                .opacity(Double(p))
                .scaleEffect((0.80 * invP) + (1.0 * p))
        }
        .frame(width: 140, height: 140)
    }

    private func drawMetaballGeometry(
        in context: GraphicsContext,
        center: CGPoint,
        c1: (CGFloat, CGFloat, CGFloat),
        c2: (CGFloat, CGFloat, CGFloat),
        c3: (CGFloat, CGFloat, CGFloat),
        c4: (CGFloat, CGFloat, CGFloat),
        centerR: CGFloat,
        edgeR: CGFloat,
        p: CGFloat
    ) {
        // 1. Center Core
        let pCenter = Path(ellipseIn: CGRect(x: center.x - centerR, y: center.y - centerR, width: centerR * 2, height: centerR * 2))
        context.fill(pCenter, with: .color(.black))

        // 2. The 4 Quadrant Corner Orbs
        let p1 = Path(ellipseIn: CGRect(x: center.x + c1.0 - c1.2, y: center.y + c1.1 - c1.2, width: c1.2 * 2, height: c1.2 * 2))
        let p2 = Path(ellipseIn: CGRect(x: center.x + c2.0 - c2.2, y: center.y + c2.1 - c2.2, width: c2.2 * 2, height: c2.2 * 2))
        let p3 = Path(ellipseIn: CGRect(x: center.x + c3.0 - c3.2, y: center.y + c3.1 - c3.2, width: c3.2 * 2, height: c3.2 * 2))
        let p4 = Path(ellipseIn: CGRect(x: center.x + c4.0 - c4.2, y: center.y + c4.1 - c4.2, width: c4.2 * 2, height: c4.2 * 2))

        context.fill(p1, with: .color(.black))
        context.fill(p2, with: .color(.black))
        context.fill(p3, with: .color(.black))
        context.fill(p4, with: .color(.black))

        // 3. Four Edge Straighteners (morph into flat squircle sides when p > 0.0)
        if edgeR > 0.1 {
            let topEdge = Path(ellipseIn: CGRect(x: center.x - edgeR, y: center.y - 16.0 * p - edgeR, width: edgeR * 2, height: edgeR * 2))
            let bottomEdge = Path(ellipseIn: CGRect(x: center.x - edgeR, y: center.y + 16.0 * p - edgeR, width: edgeR * 2, height: edgeR * 2))
            let leftEdge = Path(ellipseIn: CGRect(x: center.x - 16.0 * p - edgeR, y: center.y - edgeR, width: edgeR * 2, height: edgeR * 2))
            let rightEdge = Path(ellipseIn: CGRect(x: center.x + 16.0 * p - edgeR, y: center.y - edgeR, width: edgeR * 2, height: edgeR * 2))

            context.fill(topEdge, with: .color(.black))
            context.fill(bottomEdge, with: .color(.black))
            context.fill(leftEdge, with: .color(.black))
            context.fill(rightEdge, with: .color(.black))
        }
    }
}
