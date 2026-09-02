import SwiftUI

public struct MGGlassToggle: View {
    public let title: String
    @Binding public var isOn: Bool
    public var accentColor: Color

    @State private var isPressed: Bool = false
    @State private var isDragging: Bool = false
    @State private var dragOffset: CGFloat = 0
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

            // Direct Manipulation Liquid Glass Toggle Track & Lens
            ZStack(alignment: .leading) {
                // 1. Subordinate Track (Shows clearly under the lens)
                Capsule()
                    .fill(
                        isOn
                            ? LinearGradient(colors: [accentColor, accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.primary.opacity(0.14), Color.primary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOn ? accentColor.opacity(0.40) : Color.primary.opacity(0.08), lineWidth: 0.8)
                    )
                    .shadow(color: isOn ? accentColor.opacity(0.25) : Color.clear, radius: 4, y: 1.5)

                // 2. Liquid Glass Lens Thumb (Permanently Optical, Lifts on Press/Drag)
                lensThumb
                    .offset(x: calculatedThumbOffset)
            }
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.76)) {
                    isOn.toggle()
                }
            }
            .simultaneousGesture(
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
        }
    }

    private var calculatedThumbOffset: CGFloat {
        if isDragging {
            return thumbPadding + dragOffset
        }
        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
        return thumbPadding + (isOn ? maxOffset : 0)
    }

    private var isDirectlyManipulating: Bool {
        isPressed || isDragging
    }

    // MARK: - Crystal-Clear Liquid Glass Lens Thumb
    private var lensThumb: some View {
        ZStack {
            // Optical Glass Lens Substrate (Borderline Transparent, Dynamic Refraction)
            Circle()
                .fill(Color.white.opacity(isDirectlyManipulating ? 0.05 : 0.15))
                .frame(width: thumbSize, height: thumbSize)
                .glassEffect(isDirectlyManipulating ? .regular.interactive() : .regular, in: Circle())

            // Specular Convex Lens Highlight
            VStack {
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isDirectlyManipulating ? 0.70 : 0.45), location: 0.0),
                                .init(color: Color.white.opacity(0.08), location: 0.45),
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
                            .init(color: Color.white.opacity(isDirectlyManipulating ? 0.90 : 0.60), location: 0.0),
                            .init(color: Color.white.opacity(0.15), location: 0.5),
                            .init(color: Color.white.opacity(isDirectlyManipulating ? 0.50 : 0.30), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: thumbSize, height: thumbSize)
        }
        .scaleEffect(isDirectlyManipulating ? LiquidGlassTokens.interactionScale : 1.0)
        .shadow(color: Color.black.opacity(isDirectlyManipulating ? 0.22 : 0.10), radius: isDirectlyManipulating ? 6 : 2.5, y: isDirectlyManipulating ? 3 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.76), value: isDirectlyManipulating)
    }
}
