import SwiftUI

public struct FloatingDetailGlassPanel: View {
    @ObservedObject var engine: EngineService
    let game: GameItem
    let onClose: () -> Void

    public init(engine: EngineService, game: GameItem, onClose: @escaping () -> Void) {
        self.engine = engine
        self.game = game
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with Close / Collapse button
            HStack {
                Text(game.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close inspector")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            Divider()
                .opacity(0.15)

            // Game Detail Content
            GameDetailView(engine: engine, game: game)
        }
        .frame(width: 440)
        .frame(maxHeight: .infinity)
        .crystalClearSidebarGlass(cornerRadius: 22)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: -4, y: 6)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
}
