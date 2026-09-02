import SwiftUI

public struct FloatingDetailGlassPanel: View {
    @ObservedObject var engine: EngineService
    let game: GameItem
    var panelWidth: CGFloat = 420
    let onClose: () -> Void

    public init(engine: EngineService, game: GameItem, panelWidth: CGFloat = 420, onClose: @escaping () -> Void) {
        self.engine = engine
        self.game = game
        self.panelWidth = panelWidth
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with Close / Collapse button
            HStack {
                Text(game.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close inspector")
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.15)

            // Game Detail Content
            GameDetailView(engine: engine, game: game)
                .clipped()
        }
        .frame(width: panelWidth)
        .frame(maxHeight: .infinity)
        .crystalClearSidebarGlass(cornerRadius: 22)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.trailing, 18)
        .padding(.vertical, 16)
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: -4, y: 6)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
}
