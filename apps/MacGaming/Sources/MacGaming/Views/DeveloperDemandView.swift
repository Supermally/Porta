import SwiftUI

public struct DeveloperDemandView: View {
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
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                        Text("Request macOS Support — Studio Demand Campaigns")
                            .font(.system(size: 22, weight: .bold))
                    }

                    Text("Mac Gaming turns player interest into verifiable commercial demand metrics to demonstrate the viability of native Apple Silicon ports to game developers and publishers.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Studio Pitch Sheet Callout
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text("How Demand Campaigns Work")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text("When Mac gamers request support, we verify their Apple Silicon hardware specs (e.g. M2 Pro, M3 Max) and aggregate anonymous data to show game studios the exact addressable revenue and performance feasibility of a native Metal 3 port.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Campaigns List
                Text("Active Studio Petitions & Demand Leaderboard")
                    .font(.system(size: 16, weight: .bold))

                ForEach(engine.demandCampaigns) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 17, weight: .bold))
                                Text("Published by \(item.publisher)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(item.status)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.18))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                        }

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verified Mac Gamers")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text("\(item.totalRequests.formatted()) Requests")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.accentColor)
                            }

                            Divider().frame(height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Commercial Opportunity")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(item.commercialEstimate)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }

                        // Vote Button
                        HStack {
                            Text("Your Host System: \(engine.hardware.chipName) (\(engine.hardware.memoryGB) GB Unified Memory)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: {
                                engine.voteForDemandCampaign(id: item.id)
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: item.hasVoted ? "checkmark.circle.fill" : "hand.thumbsup.fill")
                                    Text(item.hasVoted ? "Vote Verified & Counted" : "Add Verified Mac Request")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(item.hasVoted ? Color.green : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
