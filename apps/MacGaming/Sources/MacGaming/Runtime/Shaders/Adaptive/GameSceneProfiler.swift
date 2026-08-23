import Foundation

public enum GameSceneState: String, Codable, Sendable {
    case mainMenu = "Main Menu"
    case loadingScreen = "Loading Screen"
    case inGameGameplay = "In-Game Gameplay"
    case cinematicCutscene = "Cinematic / Cutscene"
}

public enum RenderPathType: String, Codable, Sendable {
    case forward = "Forward Rendering"
    case deferredGBuffer = "Deferred G-Buffer Pass"
    case shadowCascade = "Cascaded Shadow Maps"
    case lightingAndReflections = "Lighting & Screen-Space Reflections"
    case postProcessing = "Post-Processing & Tonemapping"
    case userInterface = "User Interface & Overlays"
}

public struct SceneProfileCluster: Codable, Sendable {
    public let scene: GameSceneState
    public var associatedShaderHashes: [String]
    public var dominantRenderPaths: [RenderPathType]
}

public final class GameSceneProfiler: ObservableObject, @unchecked Sendable {
    public static let shared = GameSceneProfiler()

    @Published public var currentSceneState: GameSceneState = .mainMenu
    @Published public var detectedClustersCount: Int = 1

    private var clusters: [GameSceneState: SceneProfileCluster] = [:]
    private let lock = NSLock()

    public init() {
        for state in [GameSceneState.mainMenu, .loadingScreen, .inGameGameplay, .cinematicCutscene] {
            clusters[state] = SceneProfileCluster(
                scene: state,
                associatedShaderHashes: [],
                dominantRenderPaths: [.userInterface]
            )
        }
    }

    public func transitionScene(to state: GameSceneState) {
        lock.lock()
        defer { lock.unlock() }

        DispatchQueue.main.async {
            self.currentSceneState = state
        }
    }

    public func associateShaderWithCurrentScene(hash: String, path: RenderPathType) {
        lock.lock()
        defer { lock.unlock() }

        var cluster = clusters[currentSceneState] ?? SceneProfileCluster(
            scene: currentSceneState,
            associatedShaderHashes: [],
            dominantRenderPaths: []
        )

        if !cluster.associatedShaderHashes.contains(hash) {
            cluster.associatedShaderHashes.append(hash)
        }
        if !cluster.dominantRenderPaths.contains(path) {
            cluster.dominantRenderPaths.append(path)
        }

        clusters[currentSceneState] = cluster
        DispatchQueue.main.async {
            self.detectedClustersCount = self.clusters.count
        }
    }

    public func getCluster(for state: GameSceneState) -> SceneProfileCluster? {
        lock.lock()
        defer { lock.unlock() }
        return clusters[state]
    }
}
