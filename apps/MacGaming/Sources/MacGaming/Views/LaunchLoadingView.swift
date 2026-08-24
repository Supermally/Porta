import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void

    // MARK: - Animation States
    @State private var auroraDrift: Bool = false
    @State private var blobPhase: Int = 0
    @State private var isGooVisible: Bool = true
    @State private var isIconVisible: Bool = false
    @State private var isWordmarkVisible: Bool = false
    @State private var isFadingOut: Bool = false

    // Blob Metaball Components
    @State private var circle1Offset: CGSize = CGSize(width: -14, height: -10)
    @State private var circle1Scale: CGFloat = 0.95
    @State private var circle2Offset: CGSize = CGSize(width: 16, height: -8)
    @State private var circle2Scale: CGFloat = 1.10
    @State private var circle3Offset: CGSize = CGSize(width: -8, height: 16)
    @State private var circle3Scale: CGFloat = 0.85

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // 1. Base Dark Canvas
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // 2. Slow-Drifting Aurora Background
            auroraBackground
                .ignoresSafeArea()

            // 3. Central Brand Composition (Metaball Blob -> Settled Glass Icon -> Wordmark)
            VStack(spacing: 16) {
                ZStack {
                    // Stage A: Metaball / Goo Composited Liquid Blob
                    if isGooVisible {
                        gooMetaballBlob
                            .transition(.opacity)
                    }

                    // Stage B: Crisp Settled Liquid Glass App Icon Tile
                    if isIconVisible {
                        settledGlassIcon
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
                .opacity(isWordmarkVisible ? 1.0 : 0.0)
                .offset(y: isWordmarkVisible ? 0 : 6)
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .onAppear {
            runLaunchSequence()
        }
    }

    // MARK: - Aurora Background Layer
    private var auroraBackground: some View {
        ZStack {
            // Cool Blue Radial Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.15, green: 0.35, blue: 0.95).opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: auroraDrift ? -90 : 70, y: auroraDrift ? -60 : 80)

            // Soft Pink / Magenta Ambient Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.90, green: 0.25, blue: 0.60).opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 240
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: auroraDrift ? 80 : -70, y: auroraDrift ? 70 : -50)

            // Pale Teal / Cyan Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.80, blue: 0.75).opacity(0.28), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: auroraDrift ? 40 : -50, y: auroraDrift ? -80 : 60)

            // Subtle Violet Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.45, green: 0.15, blue: 0.85).opacity(0.30), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: auroraDrift ? -40 : 30, y: auroraDrift ? 30 : -40)
        }
        .blur(radius: 65)
    }

    // MARK: - Goo Metaball Compositing Layer
    private var gooMetaballBlob: some View {
        ZStack {
            // Independent Soft-Edged Circles Flattened onto GPU Layer
            ZStack {
                // Circle 1
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.25, green: 0.55, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44 * circle1Scale, height: 44 * circle1Scale)
                    .offset(circle1Offset)

                // Circle 2
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.75, blue: 1.0), Color(red: 0.55, green: 0.25, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40 * circle2Scale, height: 40 * circle2Scale)
                    .offset(circle2Offset)

                // Circle 3
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.20, green: 0.90, blue: 0.85), Color(red: 0.15, green: 0.45, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36 * circle3Scale, height: 36 * circle3Scale)
                    .offset(circle3Offset)
            }
            .frame(width: 140, height: 140)
            .drawingGroup() // Metal-backed layer flattening
            .blur(radius: 20) // Gaussian blur softens edges
            .contrast(32) // Sharp contrast boost snaps overlapping blurred edges into one seamless liquid silhouette
            .brightness(0.04)
        }
        .frame(width: 60, height: 60)
    }

    // MARK: - Crisp Settled Liquid Glass Icon Asset
    private var settledGlassIcon: some View {
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

            // Specular Glass Rim Light Stroke
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.70), Color.white.opacity(0.15), Color.clear],
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
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
        }
    }

    // MARK: - Launch Timeline Orchestrator
    private func runLaunchSequence() {
        // Continuous ambient aurora drift
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            auroraDrift = true
        }

        // Accessibility Check: Reduced Motion
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isGooVisible = false
            withAnimation(.easeOut(duration: 0.2)) {
                isIconVisible = true
                isWordmarkVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finishLaunch()
            }
            return
        }

        // 0.0s – ~0.7s: Blob Wave 1 (Organic Wobble & Asymmetrical Drift)
        withAnimation(.easeInOut(duration: 0.75)) {
            circle1Offset = CGSize(width: 14, height: 8)
            circle1Scale = 1.15

            circle2Offset = CGSize(width: -12, height: 12)
            circle2Scale = 0.88

            circle3Offset = CGSize(width: 10, height: -14)
            circle3Scale = 1.10
        }

        // ~0.75s – ~1.45s: Blob Wave 2 (Counter-Oscillation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeInOut(duration: 0.70)) {
                self.circle1Offset = CGSize(width: -8, height: 10)
                self.circle1Scale = 0.90

                self.circle2Offset = CGSize(width: 10, height: -10)
                self.circle2Scale = 1.12

                self.circle3Offset = CGSize(width: -10, height: -8)
                self.circle3Scale = 0.92
            }
        }

        // ~1.45s – ~1.70s: Convergence towards Settled Icon Center
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.circle1Offset = .zero
                self.circle1Scale = 1.0

                self.circle2Offset = .zero
                self.circle2Scale = 1.0

                self.circle3Offset = .zero
                self.circle3Scale = 1.0
            }
        }

        // ~1.70s: Crossfade from Goo Blob to Crisp Liquid Glass Icon Asset (~220ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.70) {
            withAnimation(.easeInOut(duration: 0.22)) {
                self.isGooVisible = false
                self.isIconVisible = true
            }
        }

        // ~1.90s: Wordmark Fades In with Upward Motion (~240ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.90) {
            withAnimation(.easeOut(duration: 0.24)) {
                self.isWordmarkVisible = true
            }
        }

        // ~2.25s: Clean Handoff to Main App Interface
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
            self.finishLaunch()
        }
    }

    private func finishLaunch() {
        withAnimation(.easeInOut(duration: 0.30)) {
            isFadingOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            onFinish()
        }
    }
}
