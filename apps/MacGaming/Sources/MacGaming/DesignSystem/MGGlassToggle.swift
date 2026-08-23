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

                // 2. Liquid Glass Lens Thumb (Direct Press/Drag Triggered ONLY)
                lensThumb
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
        }
    }

    private var calculatedThumbOffset: CGFloat {
        if isDragging {
            return thumbPadding + dragOffset
        }
        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
        return thumbPadding + (isOn ? maxOffset : 0)
    }

    // MARK: - Direct Manipulation State (Strictly Press / Drag, NEVER Hover)
    private var isDirectlyManipulating: Bool {
        isPressed || isDragging
    }

    private var lensThumb: some View {
        ZStack {
            if isDirectlyManipulating && config.enabled {
                // ACTIVE LENS: Native Liquid Glass material with optical clarity
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: thumbSize, height: thumbSize)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.85), location: 0.0),
                                        .init(color: Color.white.opacity(0.20), location: 0.5),
                                        .init(color: Color.white.opacity(0.50), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
            } else {
                // RESTING STATE: Quiet, clean solid thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
            }
        }
        .scaleEffect(isDirectlyManipulating ? LiquidGlassTokens.interactionScale : 1.0)
        .shadow(color: Color.black.opacity(isDirectlyManipulating ? 0.20 : 0.08), radius: isDirectlyManipulating ? 6 : 2, y: isDirectlyManipulating ? 3 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.74), value: isDirectlyManipulating)
    }
}
