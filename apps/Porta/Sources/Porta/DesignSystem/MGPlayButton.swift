import SwiftUI

public enum MGPlayButtonState: Equatable {
    case idle
    case preparing
    case launching
    case running
}

public struct MGPlayButton: View {
    public let state: MGPlayButtonState
    public let onPlay: () -> Void
    public let onStop: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        state: MGPlayButtonState = .idle,
        onPlay: @escaping () -> Void,
        onStop: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onPlay = onPlay
        self.onStop = onStop
    }

    public var body: some View {
        Group {
            switch state {
            case .idle:
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Play")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)

            case .preparing:
                Button(action: {}) {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Preparing…")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glass)
                .disabled(true)

            case .launching:
                Button(action: {}) {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Launching…")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .disabled(true)

            case .running:
                Button(action: onStop) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                        Text("Running (Stop)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glass)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: state)
    }
}
