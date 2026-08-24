import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void
    @Environment(\.colorScheme) var colorScheme

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        Group {
            if colorScheme == .light {
                LaunchLoadingLightView(onFinish: onFinish)
            } else {
                LaunchLoadingDarkView(onFinish: onFinish)
            }
        }
    }
}

// MARK: - 1. Dark Mode Launch Loading View (Deep Space Clear Soap Bubble)
private struct LaunchLoadingDarkView: View {
    let onFinish: () -> Void

    @State private var settleProgress: Double = 0.0 // 0.0 = fluid bubble, 1.0 = settled icon squircle
    @State private var showWordmark: Bool = true
    @State private var showEnterButton: Bool = true
    @State private var isEntering: Bool = false
    @State private var isFadingOut: Bool = false
    @State private var auroraPulse: Bool = false
    @State private var isButtonPressed: Bool = false

    var body: some View {
        ZStack {
            // 1. Ultra-Deep Dark Space Canvas
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            // 2. High-Fidelity Ambient Aurora Glow
            darkAuroraBackground
                .ignoresSafeArea()

            // 3. Central Soap Bubble Brand Composition
            VStack(spacing: 26) {
                // Clear Iridescent Soap Bubble
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    ClearSoapBubbleTile(time: time, settleProgress: settleProgress, isDarkMode: true)
                }
                .frame(width: 84, height: 84)

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

                // Interactive Controls
                if showEnterButton {
                    HStack(spacing: 14) {
                        // Settle / Wobble Toggle
                        Button(action: {
                            toggleMorph()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: settleProgress > 0.5 ? "bubbles.and.sparkles" : "square.dashed")
                                    .font(.system(size: 11, weight: .bold))
                                Text(settleProgress > 0.5 ? "Wobble Bubble" : "Settle to Icon")
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

    private func toggleMorph() {
        if settleProgress > 0.5 {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                settleProgress = 0.0
            }
        } else {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.80)) {
                settleProgress = 1.0
            }
        }
    }

    private func enterForge() {
        isEntering = true
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            settleProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.isFadingOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.onFinish()
            }
        }
    }

    private var darkAuroraBackground: some View {
        ZStack {
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

// MARK: - 2. Light Mode Launch Loading View (Frosted Crystal Soap Bubble)
private struct LaunchLoadingLightView: View {
    let onFinish: () -> Void

    @State private var settleProgress: Double = 0.0
    @State private var showWordmark: Bool = true
    @State private var showEnterButton: Bool = true
    @State private var isEntering: Bool = false
    @State private var isFadingOut: Bool = false
    @State private var auroraPulse: Bool = false
    @State private var isButtonPressed: Bool = false

    var body: some View {
        ZStack {
            // 1. Frosted Pearl Canvas
            Color(red: 0.96, green: 0.97, blue: 0.99)
                .ignoresSafeArea()

            // 2. High-Fidelity Ambient Pastel Aurora
            lightAuroraBackground
                .ignoresSafeArea()

            // 3. Central Soap Bubble Brand Composition
            VStack(spacing: 26) {
                // Clear Iridescent Soap Bubble
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    ClearSoapBubbleTile(time: time, settleProgress: settleProgress, isDarkMode: false)
                }
                .frame(width: 84, height: 84)

                // Brand Wordmark
                VStack(spacing: 4) {
                    Text("Forge")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.12))
                        .tracking(1.0)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 1)

                    Text("Windows Software Platform")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.42, green: 0.46, blue: 0.54))
                        .tracking(0.4)
                }
                .opacity(showWordmark ? 1.0 : 0.0)
                .offset(y: showWordmark ? 0 : 6)

                // Interactive Controls
                if showEnterButton {
                    HStack(spacing: 14) {
                        // Settle / Wobble Toggle
                        Button(action: {
                            toggleMorph()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: settleProgress > 0.5 ? "bubbles.and.sparkles" : "square.dashed")
                                    .font(.system(size: 11, weight: .bold))
                                Text(settleProgress > 0.5 ? "Wobble Bubble" : "Settle to Icon")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.04))
                                    .background(.ultraThinMaterial, in: Capsule())
                            )
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.20))
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                                            colors: [Color(red: 0.00, green: 0.48, blue: 1.00), Color(red: 0.25, green: 0.20, blue: 0.90)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color(red: 0.00, green: 0.48, blue: 1.00).opacity(0.35), radius: 10, y: 3)
                            )
                            .foregroundColor(.white)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6), Color.clear],
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

    private func toggleMorph() {
        if settleProgress > 0.5 {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                settleProgress = 0.0
            }
        } else {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.80)) {
                settleProgress = 1.0
            }
        }
    }

    private func enterForge() {
        isEntering = true
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            settleProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.isFadingOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.onFinish()
            }
        }
    }

    private var lightAuroraBackground: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.25, green: 0.60, blue: 1.0).opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: auroraPulse ? -80 : 70, y: auroraPulse ? -60 : 80)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.40, blue: 0.65).opacity(0.14), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 250
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: auroraPulse ? 80 : -70, y: auroraPulse ? 70 : -50)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.20, green: 0.85, blue: 0.70).opacity(0.16), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 230
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: auroraPulse ? 40 : -50, y: auroraPulse ? -80 : 60)
        }
        .blur(radius: 55)
    }
}

// MARK: - 100% Clear Iridescent Soap Bubble (Hollow Center, Organic Point Glints, Defined Drop Shadows)
private struct ClearSoapBubbleTile: View {
    let time: Double
    let settleProgress: Double
    var isDarkMode: Bool = true

    var body: some View {
        let p = CGFloat(settleProgress)
        let invP = 1.0 - p

        // Gentle harmonic bubble wobble physics
        let w1X = CGFloat(sin(time * 1.25)) * 7.0
        let w1Y = CGFloat(cos(time * 0.95)) * 6.0

        let w2X = CGFloat(cos(time * 1.40)) * 6.5
        let w2Y = CGFloat(sin(time * 1.15)) * 6.0

        let w3X = CGFloat(sin(time * 1.60)) * 6.0
        let w3Y = CGFloat(-cos(time * 1.05)) * 6.5

        let w4X = CGFloat(-cos(time * 1.30)) * 6.0
        let w4Y = CGFloat(-sin(time * 1.50)) * 5.5

        // Morphing 4-Corner Bubble Coordinates:
        let c1X = (-16.0 * p) + (w1X * invP)
        let c1Y = (-16.0 * p) + (w1Y * invP)
        let c1R = (17.5 * p) + (24.0 * invP)

        let c2X = (16.0 * p) + (w2X * invP)
        let c2Y = (-16.0 * p) + (w2Y * invP)
        let c2R = (17.5 * p) + (22.0 * invP)

        let c3X = (16.0 * p) + (w3X * invP)
        let c3Y = (16.0 * p) + (w3Y * invP)
        let c3R = (17.5 * p) + (20.0 * invP)

        let c4X = (-16.0 * p) + (w4X * invP)
        let c4Y = (16.0 * p) + (w4Y * invP)
        let c4R = (17.5 * p) + (18.0 * invP)

        let centerR = (22.0 * p) + (24.0 * invP)
        let edgeR = 15.0 * p

        ZStack {
            // Layer 1A: Deep Obsidian Contrast Shadow (gives clear separation against backgrounds)
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: Color.black.opacity(isDarkMode ? 0.65 : 0.22)))
                context.addFilter(.blur(radius: 12))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + 6)
                    drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                }
            }
            .blur(radius: 10)

            // Layer 1B: Soft Cyan/Blue Ambient Caustic Glow Shadow
            Canvas { context, size in
                let shadowColor = isDarkMode ? Color.blue.opacity(0.40) : Color(red: 0.00, green: 0.45, blue: 0.95).opacity(0.20)
                context.addFilter(.alphaThreshold(min: 0.5, color: shadowColor))
                context.addFilter(.blur(radius: 16))
                context.drawLayer { ctx in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + 8)
                    drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                }
            }
            .blur(radius: 12)

            // Layer 2: Ethereal Clear Glass Refraction (Subtle translucent body, center is see-through)
            LinearGradient(
                colors: [
                    Color.white.opacity(isDarkMode ? 0.10 : 0.18),
                    Color.clear,
                    Color.cyan.opacity(isDarkMode ? 0.08 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.48, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )

            // Layer 3: Vibrant Iridescent Soap Film Sheen Along Outer Boundary
            AngularGradient(
                colors: [
                    Color(red: 1.00, green: 0.30, blue: 0.75).opacity(0.75), // Magenta
                    Color(red: 0.65, green: 0.25, blue: 1.00).opacity(0.65), // Violet
                    Color(red: 0.00, green: 0.90, blue: 1.00).opacity(0.80), // Cyan
                    Color(red: 0.15, green: 0.95, blue: 0.55).opacity(0.60), // Lime Green
                    Color(red: 1.00, green: 0.85, blue: 0.20).opacity(0.70), // Golden Amber
                    Color(red: 1.00, green: 0.30, blue: 0.75).opacity(0.75)  // Loop
                ],
                center: .center,
                angle: .degrees(time * 20.0)
            )
            .mask(
                // Hollow Ring Mask: Only defines the outer soap film ring
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color.white.opacity(0.45),
                        Color.white
                    ],
                    center: .center,
                    startRadius: 16,
                    endRadius: 40
                )
            )
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.48, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )

            // Layer 4: Natural Curved Specular Glints (Soft Organic Ellipses, Zero Rectangular Streaks)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // 4A: Top-Left Primary Specular Light Glint
                let g1X = (center.x - 14 * p) + (c1X * 0.45 * invP)
                let g1Y = (center.y - 14 * p) + (c1Y * 0.45 * invP)
                let g1W = (16.0 * p) + (14.0 * invP)
                let g1H = (12.0 * p) + (10.0 * invP)

                let glint1Path = Path(ellipseIn: CGRect(x: g1X - g1W / 2, y: g1Y - g1H / 2, width: g1W, height: g1H))
                context.fill(
                    glint1Path,
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.40), Color.clear]),
                        center: CGPoint(x: g1X, y: g1Y),
                        startRadius: 0,
                        endRadius: g1W * 0.7
                    )
                )

                // 4B: Secondary Subtle Corner Droplet Glint
                let g2X = (center.x - 6 * p) + (c1X * 0.25 * invP) - 8
                let g2Y = (center.y - 18 * p) + (c1Y * 0.25 * invP)
                let glint2Path = Path(ellipseIn: CGRect(x: g2X - 3, y: g2Y - 3, width: 6, height: 6))
                context.fill(
                    glint2Path,
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.85), Color.clear]),
                        center: CGPoint(x: g2X, y: g2Y),
                        startRadius: 0,
                        endRadius: 3.5
                    )
                )

                // 4C: Bottom-Right Soft Ground Bounce Glint
                let g3X = (center.x + 12 * p) + (c3X * 0.40 * invP)
                let g3Y = (center.y + 12 * p) + (c3Y * 0.40 * invP)
                let g3W = (14.0 * p) + (12.0 * invP)
                let g3H = (9.0 * p) + (8.0 * invP)

                let glint3Path = Path(ellipseIn: CGRect(x: g3X - g3W / 2, y: g3Y - g3H / 2, width: g3W, height: g3H))
                context.fill(
                    glint3Path,
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.55), Color.cyan.opacity(0.35), Color.clear]),
                        center: CGPoint(x: g3X, y: g3Y),
                        startRadius: 0,
                        endRadius: g3W * 0.6
                    )
                )
            }
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.48, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )

            // Layer 5: High-Contrast Crisp Soap Film Outer Rim Line
            LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color.cyan.opacity(0.85),
                    Color.pink.opacity(0.70),
                    Color.white.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color.white.opacity(0.60),
                        Color.white
                    ],
                    center: .center,
                    startRadius: 24,
                    endRadius: 39
                )
            )
            .mask(
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.50, color: .white))
                    context.addFilter(.blur(radius: 11))
                    context.drawLayer { ctx in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        drawMetaballGeometry(in: ctx, center: center, c1: (c1X, c1Y, c1R), c2: (c2X, c2Y, c2R), c3: (c3X, c3Y, c3R), c4: (c4X, c4Y, c4R), centerR: centerR, edgeR: edgeR, p: p)
                    }
                }
            )
            .opacity((0.85 * invP) + (1.0 * p))

            // Layer 6: Embedded Icon Glyph (Suspended Inside the Clear Bubble Volume)
            Image(systemName: "cube.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.blue.opacity(isDarkMode ? 0.65 : 0.40), radius: 6, y: 2)
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
        let pCenter = Path(ellipseIn: CGRect(x: center.x - centerR, y: center.y - centerR, width: centerR * 2, height: centerR * 2))
        context.fill(pCenter, with: .color(.black))

        let p1 = Path(ellipseIn: CGRect(x: center.x + c1.0 - c1.2, y: center.y + c1.1 - c1.2, width: c1.2 * 2, height: c1.2 * 2))
        let p2 = Path(ellipseIn: CGRect(x: center.x + c2.0 - c2.2, y: center.y + c2.1 - c2.2, width: c2.2 * 2, height: c2.2 * 2))
        let p3 = Path(ellipseIn: CGRect(x: center.x + c3.0 - c3.2, y: center.y + c3.1 - c3.2, width: c3.2 * 2, height: c3.2 * 2))
        let p4 = Path(ellipseIn: CGRect(x: center.x + c4.0 - c4.2, y: center.y + c4.1 - c4.2, width: c4.2 * 2, height: c4.2 * 2))

        context.fill(p1, with: .color(.black))
        context.fill(p2, with: .color(.black))
        context.fill(p3, with: .color(.black))
        context.fill(p4, with: .color(.black))

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
