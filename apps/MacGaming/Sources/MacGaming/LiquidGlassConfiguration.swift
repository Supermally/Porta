import SwiftUI

public enum GlassVariant: String, CaseIterable, Identifiable, Sendable {
    case automatic = "Automatic"
    case regular = "Regular"
    case clear = "Clear"

    public var id: String { rawValue }
}

public enum InteractionResponseLevel: String, CaseIterable, Identifiable, Sendable {
    case full = "Full"
    case reduced = "Reduced"
    case off = "Off"

    public var id: String { rawValue }
}

public enum MorphingMode: String, CaseIterable, Identifiable, Sendable {
    case full = "Full"
    case reduced = "Reduced"
    case off = "Off"

    public var id: String { rawValue }
}

public struct LiquidGlassConfiguration: Equatable, Sendable {
    public var enabled: Bool = true
    public var variant: GlassVariant = .automatic
    public var accentTint: Color? = nil
    public var interactionResponse: InteractionResponseLevel = .full
    public var morphingMode: MorphingMode = .full

    public init(
        enabled: Bool = true,
        variant: GlassVariant = .automatic,
        accentTint: Color? = nil,
        interactionResponse: InteractionResponseLevel = .full,
        morphingMode: MorphingMode = .full
    ) {
        self.enabled = enabled
        self.variant = variant
        self.accentTint = accentTint
        self.interactionResponse = interactionResponse
        self.morphingMode = morphingMode
    }
}

// MARK: - Environment Key
private struct LiquidGlassConfigurationKey: EnvironmentKey {
    static let defaultValue: LiquidGlassConfiguration = LiquidGlassConfiguration()
}

public extension EnvironmentValues {
    var liquidGlassConfiguration: LiquidGlassConfiguration {
        get { self[LiquidGlassConfigurationKey.self] }
        set { self[LiquidGlassConfigurationKey.self] = newValue }
    }
}

public extension View {
    func liquidGlassConfiguration(_ config: LiquidGlassConfiguration) -> some View {
        self.environment(\.liquidGlassConfiguration, config)
    }
}
