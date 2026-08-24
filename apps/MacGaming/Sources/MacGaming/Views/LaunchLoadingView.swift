import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void

    // MARK: - Animation States
    @State private var isWobbling: Bool = false
    @State private var isSettled: Bool = false
    @State private var showCrispIcon: Bool = false
    @State private var showWordmark: Bool = false
    @State private var isFadingOut: Bool = false
    @State private var auroraPulse: Bool = false

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // 1. Dark Space Canvas
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // 2. Slow-Drifting Aurora Background (GPU Rendered)
            auroraBackground
                .ignoresSafeArea()

            // 3. Center Brand Composition
            VStack(spacing: 18) {
                ZStack {
                    // Stage A: Fluid Liquid Glass Metaball Blob (Goo Composited)
                    if !showCrispIcon {
                        liquidMetaballBlob
                            .transition(.opacity)
                    }

                    // Stage B: Crisp Settled Liquid Glass Icon Asset
                    if showCrispIcon {
                        crispGlassIcon
                            .transition(.opacity)
                    }
                }
                .frame(width: 72, height: 72)

                // Stage C: Brand Wordmark
                VStack(spacing: 3) {
                    Text("Forge")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.8)

                    Text("Windows Software Platform")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .tracking(0.3)
                }
                .opacity(showWordmark ? 1.0 : 0.0)
                .offset(y: showWordmark ? 0 : 5)
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Aurora Background
    private var auroraBackground: some View {
        ZStack {
            // Cool Blue Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.15, green: 0.35, blue: 0.95).opacity(0.30), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
                .frame(width: 460, height: 460)
                .offset(x: auroraPulse ? -70 : 60, y: auroraPulse ? -50 : 70)

            // Soft Magenta Ambient Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.85, green: 0.20, blue: 0.55).opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: auroraPulse ? 70 : -60, y: auroraPulse ? 60 : -40)

            // Pale Teal Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.75, blue: 0.70).opacity(0.24), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: auroraPulse ? 30 : -40, y: auroraPulse ? -70 : 50)
        }
        .blur(radius: 50)
    }

    // MARK: - Liquid Metaball / Goo Composited Blob
    private var liquidMetaballBlob: some View {
        ZStack {
            // Circle 1: Dominant Glass Blue Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.22, green: 0.52, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: isSettled ? 46 : (isWobbling ? 48 : 38),
                    height: isSettled ? 46 : (isWobbling ? 48 : 38)
                )
                .offset(
                    x: isSettled ? 0 : (isWobbling ? 12 : -12),
                    y: isSettled ? 0 : (isWobbling ? 8 : -8)
                )

            // Circle 2: Violet / Magenta Refraction Orb
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.75, blue: 1.0), Color(red: 0.55, green: 0.25, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: isSettled ? 42 : (isWobbling ? 36 : 46),
                    height: isSettled ? 42 : (isWobbling ? 36 : 46)
                )
                .offset(
                    x: isSettled ? 0 : (isWobbling ? -10 : 14),
                    y: isSettled ? 0 : (isWobbling ? 10 : -10)
                )

            // Circle 3: Pale Cyan Edge Bead
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.90, blue: 0.85), Color(red: 0.15, green: 0.45, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: isSettled ? 38 : (isWobbling ? 42 : 32),
                    height: isSettled ? 38 : (isWobbling ? 42 : 32)
                )
                .offset(
                    x: isSettled ? 0 : (isWobbling ? 8 : -8),
                    y: isSettled ? 0 : (isWobbling ? -12 : 12)
                )
        }
        .frame(width: 120, height: 120)
        .blur(radius: 16)
        .contrast(28)
        .brightness(0.04)
        .drawingGroup() // Metal-backed GPU compositing after blur and contrast
    }

    // MARK: - Crisp Settled Liquid Glass Icon Asset
    private var crispGlassIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.48, blue: 0.98), Color(red: 0.38, green: 0.18, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .shadow(color: Color.blue.opacity(0.55), radius: 14, y: 4)

            // Specular Rim Light Bevel Stroke
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.75), Color.white.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 58, height: 58)

            // Brand Icon Glyph
            Image(systemName: "cube.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)
        }
    }

    // MARK: - Sequence Timeline
    private func startSequence() {
        // 1. Slow continuous aurora drift
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            auroraPulse = true
        }

        // 2. Reduced Motion Accessibility Check
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            showCrispIcon = true
            withAnimation(.easeOut(duration: 0.25)) {
                showWordmark = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finish()
            }
            return
        }

        // 3. Fluid Blob Wobble Phase (0.0s -> 1.4s)
        withAnimation(.easeInOut(duration: 0.70).repeatCount(2, autoreverses: true)) {
            isWobbling = true
        }

        // 4. Convergence & Settle Phase (~1.45s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(.easeOut(duration: 0.28)) {
                self.isSettled = true
            }
        }

        // 5. Crossfade from Goo Blob to Crisp Icon Asset (~1.75s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            withAnimation(.easeInOut(duration: 0.22)) {
                self.showCrispIcon = true
            }
        }

        // 6. Wordmark Reveal (~1.95s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.showWordmark = true
            }
        }

        // 7. Clean Handoff (~2.30s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
            self.finish()
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isFadingOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onFinish()
        }
    }
}
