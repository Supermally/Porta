import SwiftUI
import AppKit

// MARK: - Ultra-Lightweight, High-Performance Liquid Glass Launch Progress Bar
public struct LaunchLoadingView: View {
    let onFinish: () -> Void
    @Environment(\.colorScheme) var colorScheme

    @State private var progress: Double = 0.0
    @State private var statusText: String = "Starting Forge..."
    @State private var isFadingOut: Bool = false
    @State private var pulseGlow: Bool = false

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // 1. Dark/Light Ambient Canvas
            if colorScheme == .light {
                Color(red: 0.96, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.04, green: 0.04, blue: 0.07)
                    .ignoresSafeArea()
            }

            // 2. Soft Ambient Radial Glow (Zero CPU Overhead)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme == .light ? Color.blue.opacity(0.12) : Color.blue.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
                .frame(width: 480, height: 480)
                .scaleEffect(pulseGlow ? 1.05 : 0.95)

            // 3. Central Brand & Progress Bar
            VStack(spacing: 24) {
                // Glass App Icon Tile
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.48, blue: 1.0), Color(red: 0.35, green: 0.18, blue: 0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.blue.opacity(colorScheme == .light ? 0.30 : 0.55), radius: 16, y: 5)

                    // Specular Top-Left Rim Bevel
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color.white.opacity(0.15), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 64, height: 64)

                    // Inner Specular Reflection
                    VStack {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [Color.white.opacity(0.40), Color.clear], startPoint: .top, endPoint: .bottom))
                                .frame(width: 38, height: 16)
                                .padding(.top, 4)
                                .padding(.leading, 6)
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 64, height: 64)
                    .clipped()

                    Image(systemName: "cube.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)
                }

                // Brand Typography
                VStack(spacing: 4) {
                    Text("Forge")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .light ? Color(red: 0.08, green: 0.08, blue: 0.12) : .white)
                        .tracking(0.8)

                    Text("Windows Software Platform")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colorScheme == .light ? Color(red: 0.45, green: 0.48, blue: 0.55) : .white.opacity(0.65))
                        .tracking(0.3)
                }

                // Smooth Liquid Glass Progress Bar
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08))
                            .frame(width: 220, height: 6)
                            .overlay(
                                Capsule()
                                    .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12), lineWidth: 1)
                            )

                        // Glowing Fill Bar
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.75, blue: 1.0),
                                        Color(red: 0.20, green: 0.45, blue: 1.0),
                                        Color(red: 0.50, green: 0.20, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, 220 * CGFloat(progress)), height: 6)
                            .shadow(color: Color.blue.opacity(0.6), radius: 6, y: 1)
                    }

                    // Progress Status Text
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(colorScheme == .light ? Color.secondary : .white.opacity(0.55))
                        .transition(.opacity)
                }
                .padding(.top, 4)
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .onAppear {
            startLoadingSequence()
        }
    }

    private func startLoadingSequence() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseGlow = true
        }

        // Stage 1: Fast initial warm-up (0.0s - 0.4s)
        withAnimation(.easeOut(duration: 0.4)) {
            self.progress = 0.35
            self.statusText = "Loading cached library..."
        }

        // Stage 2: Environment verification (0.4s - 1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.65)) {
                self.progress = 0.75
                self.statusText = "Warming translation engine..."
            }

            // Stage 3: Finalizing launch (1.1s - 1.6s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
                withAnimation(.easeOut(duration: 0.45)) {
                    self.progress = 1.0
                    self.statusText = "Ready"
                }

                // Stage 4: Seamless fade into main application (1.8s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
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
}
