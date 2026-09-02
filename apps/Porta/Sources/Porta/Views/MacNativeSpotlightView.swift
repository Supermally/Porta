import SwiftUI

public struct MacNativeSpotlightView: View {
    @ObservedObject var engine: EngineService

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                        Text("Mac Native Spotlight")
                            .font(.system(size: 22, weight: .bold))
                    }

                    Text("Celebrating game studios that develop first-class native Apple Silicon experiences with Metal 3, MetalFX upscaling, and Game Controller integration.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Spotlight Cards List
                ForEach(engine.nativeSpotlights) { item in
                    VStack(alignment: .leading, spacing: 14) {
                        // Title & Studio Row
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 18, weight: .bold))
                                Text("Developed by \(item.studio)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(item.bannerTag)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.18))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }

                        Text(item.description)
                            .font(.system(size: 13))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineSpacing(2)

                        // Metal Technologies Tags
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Apple Silicon & Metal Features:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(item.metalTechnologies, id: \.self) { tech in
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 9))
                                        Text(tech)
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(6)
                                }
                            }
                        }

                        // Performance Highlight Callout
                        HStack(spacing: 8) {
                            Image(systemName: "gauge.with.needle.fill")
                                .foregroundColor(.green)
                            Text(item.performanceHighlight)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(6)
                    }
                    .padding(18)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
