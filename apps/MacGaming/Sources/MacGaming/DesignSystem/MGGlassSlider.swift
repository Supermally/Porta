import SwiftUI

public struct MGGlassSlider: View {
    @Binding public var value: Double
    public let bounds: ClosedRange<Double>
    public let step: Double
    public var gradientColors: [Color]

    @State private var isDragging: Bool = false
    @State private var isPressed: Bool = false
    @State private var dragVelocity: CGFloat = 0.0
    @State private var lastDragLocation: CGFloat = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.liquidGlassConfiguration) private var config

    private let trackHeight: CGFloat = 8
    private let thumbWidth: CGFloat = 24
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
                // 1. Resting Inactive Base Track
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: trackHeight)

                // 2. Active Gradient Track (Revealed & refracted beneath the lens)
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

                // 3. Liquid Glass Lens Knob (Active on Direct Drag/Press ONLY)
                lensKnob
                    .offset(x: currentOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isPressed = true
                                isDragging = true

                                // Momentum Velocity Tracking
                                let delta = gesture.location.x - lastDragLocation
                                lastDragLocation = gesture.location.x
                                dragVelocity = min(max(-1.0, delta / 10.0), 1.0)

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
                                isPressed = false
                                isDragging = false
                                withAnimation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.72)) {
                                    dragVelocity = 0.0
                                }
                            }
                    )
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let rawFraction = (location.x - (thumbWidth / 2)) / availableWidth
                let clamped = min(max(0, rawFraction), 1.0)
                let rawValue = bounds.lowerBound + Double(clamped) * (bounds.upperBound - bounds.lowerBound)
                
                withAnimation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.8)) {
                    if step > 0 {
                        let stepped = (rawValue / step).rounded() * step
                        value = min(max(bounds.lowerBound, stepped), bounds.upperBound)
                    } else {
                        value = min(max(bounds.lowerBound, rawValue), bounds.upperBound)
                    }
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - Direct Manipulation State (Strictly Press / Drag, NEVER Hover)
    private var isDirectlyManipulating: Bool {
        isPressed || isDragging
    }

    private var stretchFactor: CGFloat {
        if reduceMotion || !isDragging { return 1.0 }
        return 1.0 + (abs(dragVelocity) * 0.14)
    }

    private var lensKnob: some View {
        ZStack {
            if isDirectlyManipulating && config.enabled {
                // ACTIVE LENS: Native Liquid Glass material with optical clarity
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: thumbWidth, height: thumbHeight)
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.90), location: 0.0),
                                        .init(color: Color.white.opacity(0.24), location: 0.45),
                                        .init(color: Color.white.opacity(0.55), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
            } else {
                // RESTING STATE: Quiet, clean solid knob
                Capsule()
                    .fill(Color.white)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
            }
        }
        .scaleEffect(x: stretchFactor, y: isDirectlyManipulating ? 1.04 : 1.0)
        .shadow(color: Color.black.opacity(isDirectlyManipulating ? 0.20 : 0.08), radius: isDirectlyManipulating ? 6 : 2, y: isDirectlyManipulating ? 3 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.74), value: isDirectlyManipulating)
        .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.8), value: stretchFactor)
    }
}
