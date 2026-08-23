import SwiftUI

public struct MGGlassToggle: View {
    public let title: String
    @Binding public var isOn: Bool
    public var accentColor: Color

    @State private var isHovered: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    private let trackWidth: CGFloat = 50
    private let trackHeight: CGFloat = 28
    private let thumbSize: CGFloat = 24
    private let thumbPadding: CGFloat = 2

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
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Interactive Glass Toggle Track & Clear Capsule Thumb
            ZStack(alignment: .leading) {
                // 1. Base Track
                Capsule()
                    .fill(
                        isOn
                            ? LinearGradient(colors: [accentColor, accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.primary.opacity(0.12), Color.primary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOn ? accentColor.opacity(0.5) : Color.primary.opacity(0.10), lineWidth: 0.8)
                    )
                    .shadow(color: isOn ? accentColor.opacity(0.3) : Color.clear, radius: 6, y: 2)

                // 2. 3D Clear Refractive Glass Capsule Thumb
                clearGlassThumb
                    .offset(x: calculatedThumbOffset)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                    isOn.toggle()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
                        let initial = isOn ? maxOffset : 0
                        let target = initial + value.translation.width
                        dragOffset = min(max(0, target), maxOffset)
                    }
                    .onEnded { value in
                        isDragging = false
                        let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
                        let threshold = maxOffset / 2
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
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

    // MARK: - Clear Refractive Glass Thumb
    private var clearGlassThumb: some View {
        ZStack {
            // Glass Substrate (Crystal Clear with subtle refraction)
            Circle()
                .fill(Color.white.opacity(0.15))
                .background(.ultraThinMaterial, in: Circle())
                .frame(width: thumbSize, height: thumbSize)

            // Specular Top Rim Reflection
            VStack {
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.65), location: 0.0),
                                .init(color: Color.white.opacity(0.15), location: 0.45),
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

            // 3D Glass Bevel Rim Stroke
            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.90), location: 0.0),
                            .init(color: Color.white.opacity(0.30), location: 0.5),
                            .init(color: Color.white.opacity(0.60), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: thumbSize, height: thumbSize)
        }
        .shadow(color: Color.black.opacity(0.18), radius: isHovered ? 4 : 2, y: 1.5)
        .scaleEffect(isDragging ? 1.06 : (isHovered ? 1.03 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragging)
    }
}
