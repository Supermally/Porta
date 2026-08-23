import SwiftUI

public struct MGGlassToggle: View {
    public let title: String
    @Binding public var isOn: Bool
    public var accentColor: Color

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.liquidGlassConfiguration) private var config

    private let trackWidth: CGFloat = 48
    private let trackHeight: CGFloat = 28
    private let thumbSize: CGFloat = 22
    private let thumbPadding: CGFloat = 3

    public init(
        _ title: String = "",
        isOn: Binding<Bool>,
        accentColor: Color = Color(red: 0.20, green: 0.78, blue: 0.35)
    ) {
        self.title = title
        self._isOn = isOn
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Interactive Liquid Glass Lens Toggle
            ZStack(alignment: .leading) {
                // 1. Resting Subordinate Track
                Capsule()
                    .fill(
                        isOn
                            ? LinearGradient(colors: [accentColor, accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.primary.opacity(0.12), Color.primary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOn ? accentColor.opacity(0.40) : Color.primary.opacity(0.08), lineWidth: 0.8)
                    )
                    .shadow(color: isOn ? accentColor.opacity(0.25) : Color.clear, radius: 4, y: 1.5)

                // 2. Liquid Glass Lens Thumb (Materializes & Lifts on Interaction)
                liquidGlassLensThumb
                    .offset(x: calculatedThumbOffset)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.76)) {
                    isOn.toggle()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isPressed = true
                        isDragging = true
                        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
                        let initial = isOn ? maxOffset : 0
                        let target = initial + value.translation.width
                        dragOffset = min(max(0, target), maxOffset)
                    }
                    .onEnded { value in
                        isPressed = false
                        isDragging = false
                        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
                        let threshold = maxOffset / 2
                        withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.76)) {
                            if dragOffset > threshold {
                                isOn = true
                            } else {
                                isOn = false
                            }
                            dragOffset = 0
                        }
                    }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
    }

    private var calculatedThumbOffset: CGFloat {
        if isDragging {
            return thumbPadding + dragOffset
        }
        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
        return thumbPadding + (isOn ? maxOffset : 0)
    }

    // MARK: - Liquid Glass Lens Thumb
    private var isInteracting: Bool {
        isPressed || isDragging || isHovered
    }

    private var liquidGlassLensThumb: some View {
        ZStack {
            if isInteracting && config.enabled {
                // ACTIVE LENS: Clear Refractive Substrate
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .background(.ultraThinMaterial, in: Circle())
                    .frame(width: thumbSize, height: thumbSize)

                // Specular Convex Lens Highlight
                VStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.65), location: 0.0),
                                    .init(color: Color.white.opacity(0.12), location: 0.45),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: thumbSize * 0.85, height: thumbSize * 0.45)
                        .padding(.top, 1)
                    Spacer()
                }
                .clipShape(Circle())

                // 3D Glass Lens Rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.85), location: 0.0),
                                .init(color: Color.white.opacity(0.25), location: 0.5),
                                .init(color: Color.white.opacity(0.55), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                    .frame(width: thumbSize, height: thumbSize)
            } else {
                // RESTING THUMB: Clean & Quiet
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.14), radius: 2, y: 1)
            }
        }
        .scaleEffect(isInteracting ? LiquidGlassTokens.interactionScale : 1.0)
        .shadow(color: Color.black.opacity(isInteracting ? 0.22 : 0.08), radius: isInteracting ? 6 : 2, y: isInteracting ? 3 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.74), value: isInteracting)
    }
}
