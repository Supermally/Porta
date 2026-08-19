import SwiftUI
import AppKit

public struct DeveloperConsoleView: View {
    @ObservedObject var engine: EngineService
    @State private var searchText: String = ""
    @State private var selectedLevel: LogLevel? = nil
    @State private var isCopied: Bool = false

    public init(engine: EngineService) {
        self.engine = engine
    }

    private var filteredLogs: [ConsoleLogEntry] {
        engine.consoleLogs.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                entry.message.localizedCaseInsensitiveContains(searchText) ||
                entry.source.localizedCaseInsensitiveContains(searchText)

            let matchesLevel = selectedLevel == nil || entry.level == selectedLevel

            return matchesSearch && matchesLevel
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Controls & Filter Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.green)
                    Text("Developer Console")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                // Filter by Level
                Picker("Level", selection: $selectedLevel) {
                    Text("All Levels").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases) { lvl in
                        Label(lvl.rawValue, systemImage: lvl.icon).tag(lvl as LogLevel?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter logs...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
                .frame(width: 200)

                // Copy to Clipboard Button
                Button {
                    engine.copyConsoleLogsToClipboard()
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isCopied = false
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy Logs")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(isCopied ? .green : .blue)
                .help("Copy full log output to clipboard for debugging or sharing")

                // Clear Button
                Button {
                    engine.clearConsoleLogs()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Clear console logs")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.85))

            Divider()

            // Console Stream Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if filteredLogs.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text(searchText.isEmpty ? "No console logs recorded yet." : "No logs matching '\(searchText)'")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            ForEach(filteredLogs) { log in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(timeFormatter.string(from: log.timestamp))
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 85, alignment: .leading)

                                    Text(log.level.rawValue)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(log.level.color)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(log.level.color.opacity(0.15))
                                        )
                                        .frame(width: 50, alignment: .center)

                                    Text("[\(log.source)]")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.primary.opacity(0.8))
                                        .frame(minWidth: 70, alignment: .leading)

                                    Text(log.message)
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(log.level == .error ? .red : .primary)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                                .id(log.id)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .background(Color(red: 0.04, green: 0.06, blue: 0.09))
                .onChange(of: engine.consoleLogs.count) { _ in
                    if let last = engine.consoleLogs.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Footer Status & Instance Manager Info
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(engine.isGameModeActive ? Color.green : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(engine.isGameModeActive ? "Active Processes Running" : "Engine Idle")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(engine.consoleLogs.count) entries recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
