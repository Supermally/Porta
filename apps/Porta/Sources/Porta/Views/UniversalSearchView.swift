import SwiftUI

public struct UniversalSearchView: View {
    @ObservedObject var engine: EngineService

    public init(engine: EngineService) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Header Bar
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("Search any PC game in existence (e.g. Elden Ring, Minecraft, Cyberpunk, Fortnite, Valorant)...", text: $engine.catalogSearchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))

                    if !engine.catalogSearchText.isEmpty {
                        Button(action: { engine.catalogSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                        .background(.ultraThinMaterial, in: Capsule())
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .overlay(Divider().opacity(0.15), alignment: .bottom)

            // Results List
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header Summary Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Universal Compatibility Database & Search")
                                .font(.system(size: 18, weight: .bold))
                            Text("Look up any game before purchasing or downloading to see its Mac compatibility tier, recommended runtime settings, and community demand.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(engine.filteredCatalogEntries.count) Games Cataloged")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Game Cards
                    ForEach(engine.filteredCatalogEntries) { game in
                        CatalogGameCard(game: game, engine: engine)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct CatalogGameCard: View {
    let game: CatalogGameItem
    @ObservedObject var engine: EngineService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Title, Storefronts, Status Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(size: 17, weight: .bold))

                    HStack(spacing: 6) {
                        ForEach(game.storefronts, id: \.self) { sf in
                            Text(sf)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(4)
                        }

                        if let ac = game.antiCheat {
                            Text(ac)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Compatibility Status Badge
                if game.isNative {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Official Mac Native")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.18))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                } else if game.compatibilityTier == "Unsupported" {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.octagon.fill")
                        Text("Unsupported")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.18))
                    .foregroundColor(.red)
                    .cornerRadius(6)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.horizontal.fill")
                        Text("Compatible (\(game.compatibilityTier))")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.18))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
            }

            // Recommendation Banner
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Gaming Recommendation: \(game.recommendation)")
                        .font(.system(size: 12, weight: .semibold))
                    Text(game.recommendationReason)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)

            // Performance Target & "Request macOS Support" Footer
            HStack {
                if game.targetFps > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.needle.fill")
                            .foregroundColor(.green)
                        Text("Target: ~\(game.targetFps) FPS on \(engine.hardware.chipName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Requires native port from game studio.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Request Mac Version Button & Counter
                if !game.isNative {
                    Button(action: {
                        engine.requestMacSupport(for: game.id)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: game.hasUserRequested ? "hand.thumbsup.fill" : "hand.thumbsup")
                            Text(game.hasUserRequested ? "Support Requested (\(game.requestCount))" : "Request macOS Support (\(game.requestCount))")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(game.hasUserRequested ? Color.accentColor : Color.secondary.opacity(0.12))
                        .foregroundColor(game.hasUserRequested ? .white : .primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
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
