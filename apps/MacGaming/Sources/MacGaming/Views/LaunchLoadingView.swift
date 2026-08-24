import SwiftUI
import AppKit

public struct LaunchLoadingView: View {
    let onFinish: () -> Void

    // MARK: - Animation & Interactive States
    @State private var isSettled: Bool = false
    @State private var showCrispIcon: Bool = false
    @State private var showWordmark: Bool = false
    @State private var showEnterButton: Bool = false
    @State private var isFadingOut: Bool = false
    @State private var auroraPulse: Bool = false
    @State private var isButtonPressed: Bool = false

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // 1. Dark Space Canvas
            Color(red: 0.04, green: 0.04, blue: 0.07)
                .ignoresSafeArea()

            // 2. Slow-Drifting Aurora Background (GPU Rendered)
            auroraBackground
                .ignoresSafeArea()

            // 3. Central Brand Composition
            VStack(spacing: 22) {
                ZStack {
                    // Stage A: Fluid Liquid Glass Metaball Goo (Continuous GPU Fluid Physics)
                    if !showCrispIcon {
                        TimelineView(.animation) { timeline in
                            let time = timeline.date.timeIntervalSinceReferenceDate
                            gooMetaballLayer(time: time)
                        }
                        .transition(.opacity)
                    }

                    // Stage B: Crisp Settled Liquid Glass Icon Asset
                    if showCrispIcon {
                        crispGlassIcon
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                .frame(width: 80, height: 80)

                // Stage C: Brand Wordmark
                VStack(spacing: 4) {
                    Text("Forge")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.9)

                    Text("Windows Software Platform")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .tracking(0.3)
                }
                .opacity(showWordmark ? 1.0 : 0.0)
                .offset(y: showWordmark ? 0 : 6)
                .animation(.easeOut(duration: 0.4), value: showWordmark)

                // Stage D: Interactive "Enter Forge" & "Replay Goo" Controls
                if showEnterButton {
                    HStack(spacing: 12) {
                        // Replay Animation Button
                        Button(action: {
                            replaySequence()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Replay Goo")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .background(.ultraThinMaterial, in: Capsule())
                            )
                            .foregroundColor(.white.opacity(0.85))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Enter Forge Primary Button
                        Button(action: {
                            enterForge()
                        }) {
                            HStack(spacing: 8) {
                                Text("Enter Forge")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.20, green: 0.55, blue: 1.0), Color(red: 0.35, green: 0.25, blue: 0.95)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.4), radius: 10, y: 3)
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
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in withAnimation(.interactiveSpring(response: 0.15)) { isButtonPressed = true } }
                                .onEnded { _ in withAnimation(.interactiveSpring(response: 0.15)) { isButtonPressed = false } }
                        )
                    }
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Aurora Background Layer
    private var auroraBackground: some View {
        ZStack {
            // Cool Blue Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.15, green: 0.35, blue: 0.95).opacity(0.32), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 480, height: 480)
                .offset(x: auroraPulse ? -80 : 70, y: auroraPulse ? -60 : 80)

            // Soft Magenta Ambient Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.85, green: 0.20, blue: 0.55).opacity(0.24), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 240
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: auroraPulse ? 80 : -70, y: auroraPulse ? 70 : -50)

            // Pale Teal Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.75, blue: 0.70).opacity(0.26), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: auroraPulse ? 40 : -50, y: auroraPulse ? -80 : 60)
        }
        .blur(radius: 55)
    }

    // MARK: - Liquid Metaball / Goo Composited Layer (Physical Continuous Wave)
    @ViewBuilder
    private func gooMetaballLayer(time: Double) -> some View {
        let settleFactor: CGFloat = isSettled ? 0.0 : 1.0

        let off1X = CGFloat(sin(time * 2.8)) * 14.0 * settleFactor
        let off1Y = CGFloat(cos(time * 2.2)) * 10.0 * settleFactor
        let scale1 = CGFloat(1.0 + sin(time * 3.1) * 0.15 * Double(settleFactor))

        let off2X = CGFloat(cos(time * 3.2)) * 13.0 * settleFactor
        let off2Y = CGFloat(sin(time * 2.6)) * 11.0 * settleFactor
        let scale2 = CGFloat(1.0 + cos(time * 2.7) * 0.16 * Double(settleFactor))

        let off3X = CGFloat(sin(time * 3.6)) * 11.0 * settleFactor
        let off3Y = CGFloat(-cos(time * 2.4)) * 13.0 * settleFactor
        let scale3 = CGFloat(1.0 + sin(time * 3.8) * 0.14 * Double(settleFactor))

        ZStack {
            // Circle 1: Glass Blue Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.22, green: 0.52, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44 * scale1, height: 44 * scale1)
                .offset(x: off1X, y: off1Y)

            // Circle 2: Violet / Magenta Refraction
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.75, blue: 1.0), Color(red: 0.55, green: 0.25, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40 * scale2, height: 40 * scale2)
                .offset(x: off2X, y: off2Y)

            // Circle 3: Cyan Edge Bead
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.90, blue: 0.85), Color(red: 0.15, green: 0.45, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36 * scale3, height: 36 * scale3)
                .offset(x: off3X, y: off3Y)
        }
        .frame(width: 140, height: 140)
        .blur(radius: 16)
        .contrast(28)
        .brightness(0.04)
        .drawingGroup()
    }

    // MARK: - Crisp Settled Liquid Glass Icon Asset
    private var crispGlassIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.48, blue: 0.98), Color(red: 0.38, green: 0.18, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 62, height: 62)
                .shadow(color: Color.blue.opacity(0.60), radius: 16, y: 5)

            // Specular Rim Light Bevel Stroke
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.80), Color.white.opacity(0.20), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 62, height: 62)

            // Brand Icon Glyph
            Image(systemName: "cube.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)
        }
    }

    // MARK: - Sequence Timeline Orchestrator
    private func startSequence() {
        // Continuous aurora drift
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            auroraPulse = true
        }

        // Accessibility Check
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            showCrispIcon = true
            showWordmark = true
            showEnterButton = true
            return
        }

        // Step 1: Let the liquid goo blob wobble organically for 1.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.35)) {
                self.isSettled = true
            }

            // Step 2: Crossfade to crisp glass icon (~2.1s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.28)) {
                    self.showCrispIcon = true
                }

                // Step 3: Reveal wordmark (~2.4s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeOut(duration: 0.30)) {
                        self.showWordmark = true
                    }

                    // Step 4: Reveal "Enter Forge" button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            self.showEnterButton = true
                        }
                    }
                }
            }
        }
    }

    private func replaySequence() {
        withAnimation(.easeInOut(duration: 0.20)) {
            showEnterButton = false
            showWordmark = false
            showCrispIcon = false
            isSettled = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            startSequence()
        }
    }

    private func enterForge() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isFadingOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onFinish()
        }
    }
}
