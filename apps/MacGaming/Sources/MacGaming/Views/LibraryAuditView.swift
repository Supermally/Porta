import SwiftUI

public struct LibraryAuditView: View {
    @ObservedObject var engine: EngineService

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        let audit = engine.libraryAudit

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("The State of Your Library")
                        .font(.system(size: 22, weight: .bold))
                    Text("Comprehensive compatibility audit across your connected storefronts, local folders, and Apple Silicon hardware.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Hero Insight Banner
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(audit.translationReliancePct)% of your PC game library relies on Mac Gaming")
                                .font(.system(size: 18, weight: .bold))

                            Text(audit.headlineInsight)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Stacked Percentage Bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            if audit.nativeCount > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.green)
                                    .frame(width: max(8, geo.size.width * CGFloat(audit.nativePct) / 100.0))
                            }
                            if audit.compatibleCount > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.blue)
                                    .frame(width: max(8, geo.size.width * CGFloat(audit.compatiblePct) / 100.0))
                            }
                            if audit.experimentalCount > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.yellow)
                                    .frame(width: max(8, geo.size.width * CGFloat(audit.experimentalPct) / 100.0))
                            }
                            if audit.unsupportedCount > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.red)
                                    .frame(width: max(8, geo.size.width * CGFloat(audit.unsupportedPct) / 100.0))
                            }
                        }
                    }
                    .frame(height: 12)
                    .padding(.top, 4)
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )

                // 4 Metric Breakdown Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AuditMetricCard(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        title: "Native macOS",
                        count: audit.nativeCount,
                        percentage: audit.nativePct,
                        subtitle: "Runs directly on Apple Silicon with 0 translation overhead."
                    )

                    AuditMetricCard(
                        icon: "bolt.horizontal.fill",
                        color: .blue,
                        title: "Compatible & Ready",
                        count: audit.compatibleCount,
                        percentage: audit.compatiblePct,
                        subtitle: "Runs smoothly through D3DMetal & sandboxed Wine runtime."
                    )

                    AuditMetricCard(
                        icon: "wrench.adjustable.fill",
                        color: .yellow,
                        title: "Experimental / Fix Required",
                        count: audit.experimentalCount,
                        percentage: audit.experimentalPct,
                        subtitle: "Playable with community profile flags and graphical tweaks."
                    )

                    AuditMetricCard(
                        icon: "xmark.octagon.fill",
                        color: .red,
                        title: "Unsupported (Anti-Cheat)",
                        count: audit.unsupportedCount,
                        percentage: audit.unsupportedPct,
                        subtitle: "Blocked by Windows kernel-level drivers or unsupported DRM."
                    )
                }

                // Ecosystem & Developer Takeaway Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundColor(.purple)
                        Text("Why This Matters for Mac Gaming")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text("Without Mac Gaming, \(audit.translationReliancePct)% of the games in your library would be completely unplayable on macOS. By unifying your storefronts and translating Windows graphics pipelines to Apple Metal, you can bring the games you already own.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)

                    Text(audit.developerCallout)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct AuditMetricCard: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let percentage: Int
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }

            Text("\(count) Games")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
