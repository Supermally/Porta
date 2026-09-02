import SwiftUI

public struct MGGlassControl<Content: View>: View {
    public let shape: GlassShapeOption
    public let content: Content

    public init(shape: GlassShapeOption = .capsule, @ViewBuilder content: () -> Content) {
        self.shape = shape
        self.content = content()
    }

    public var body: some View {
        content
            .glassEffect(.regular.interactive(), in: shape)
    }
}
