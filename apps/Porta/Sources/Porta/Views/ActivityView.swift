import SwiftUI

public struct ActivityView: View {
    @ObservedObject var engine: EngineService
    @State private var selectedCategory: String = "All"
    @State private var selectedEvent: ActivityEvent? = nil

    private let categories = ["All", "Runtime", "Process", "Graphics", "Discovery", "Installation"]

    public init(engine: EngineService) {
        self.engine = engine
    }

    private var filteredEvents: [ActivityEvent] {
        if selectedCategory == "All" {
            return engine.activityEvents
        }
        return engine.activityEvents.filter { $0.category == selectedCategory }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity & Diagnostics")
                        .font(.system(size: 22, weight: .bold))
                    Text("Live chronological stream of runtime, graphics, and environment events.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button("Clear Activity") {
                    engine.activityEvents.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Category Filter Chips
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selectedCategory = cat }) {
                        Text(cat)
                            .font(.system(size: 12, weight: selectedCategory == cat ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? Color.blue.opacity(0.18) : Color.secondary.opacity(0.08))
                            .foregroundColor(selectedCategory == cat ? .blue : .primary)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 14)

            Divider()

            // Main Activity List
            if filteredEvents.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No activity recorded yet")
                        .font(.system(size: 15, weight: .medium))
                    Text("Runtime, application, and graphics events will appear here in real time.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(filteredEvents) { event in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: event.severity.icon)
                            .foregroundColor(event.severity.color)
                            .font(.system(size: 16))
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(event.title)
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text(event.formattedTime)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Text(event.details)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if let log = event.technicalLog, !log.isEmpty {
                                Text(log)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .padding(6)
                                    .background(Color.secondary.opacity(0.08))
                                    .cornerRadius(6)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
    }
}
