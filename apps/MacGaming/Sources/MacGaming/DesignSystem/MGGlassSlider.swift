import SwiftUI

public struct MGGlassSlider: View {
    @Binding public var value: Double
    public let bounds: ClosedRange<Double>
    public let step: Double
    public var gradientColors: [Color]

    @State private var isHovered: Bool = false
    @State private var isDragging: Bool = false

    private let trackHeight: CGFloat = 10
    private let thumbWidth: CGFloat = 26
    private let thumbHeight: CGFloat = 18

    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0.0...1.0,
        step: Double = 0.01,
        gradientColors: [Color] = [Color.blue, Color.cyan]
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.gradientColors = gradientColors
    }

    public var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(10, geometry.size.width - thumbWidth)
            let percentage = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
            let currentOffset = availableWidth * CGFloat(min(max(0, percentage), 1.0))

            ZStack(alignment: .leading) {
                // 1. Inactive Track Base
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: trackHeight)

                // 2. Active Gradient Track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(trackHeight, currentOffset + (thumbWidth / 2)), height: trackHeight)
                    .clipShape(Capsule())

                // 3. Clear 3D Glass Capsule Thumb
                clearGlassCapsuleThumb
                    .offset(x: currentOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let rawFraction = (gesture.location.x - (thumbWidth / 2)) / availableWidth
                                let clamped = min(max(0, rawFraction), 1.0)
                                let rawValue = bounds.lowerBound + Double(clamped) * (bounds.upperBound - bounds.lowerBound)
                                
                                if step > 0 {
                                    let stepped = (rawValue / step).rounded() * step
                                    value = min(max(bounds.lowerBound, stepped), bounds.upperBound)
                                } else {
                                    value = min(max(bounds.lowerBound, rawValue), bounds.upperBound)
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let rawFraction = (location.x - (thumbWidth / 2)) / availableWidth
                let clamped = min(max(0, rawFraction), 1.0)
                let rawValue = bounds.lowerBound + Double(clamped) * (bounds.upperBound - bounds.lowerBound)
                
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    if step > 0 {
                        let stepped = (rawValue / step).rounded() * step
                        value = min(max(bounds.lowerBound, stepped), bounds.upperBound)
                    } else {
                        value = min(max(bounds.lowerBound, rawValue), bounds.upperBound)
                    }
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - 3D Clear Refractive Glass Capsule Thumb
    private var clearGlassCapsuleThumb: some View {
        ZStack {
            // Optical Substrate (Crystal Clear transmission)
            Capsule()
                .fill(Color.white.opacity(0.18))
                .background(.ultraThinMaterial, in: Capsule())
                .frame(width: thumbWidth, height: thumbHeight)

            // Specular Top Convex Highlight
            VStack {
                Capsule()
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
                    .frame(width: thumbWidth * 0.85, height: thumbHeight * 0.45)
                    .padding(.top, 1)
                Spacer()
            }
            .clipShape(Capsule())

            // 3D Specular Rim Stroke
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.95), location: 0.0),
                            .init(color: Color.white.opacity(0.35), location: 0.45),
                            .init(color: Color.white.opacity(0.65), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: thumbWidth, height: thumbHeight)
        }
        .shadow(color: Color.black.opacity(0.18), radius: isDragging ? 5 : (isHovered ? 3 : 2), y: 1.5)
        .scaleEffect(isDragging ? 1.08 : (isHovered ? 1.04 : 1.0))
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isDragging)
    }
}
