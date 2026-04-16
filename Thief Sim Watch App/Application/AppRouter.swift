import Foundation
import Combine

/// Top-level navigation state.
///
/// Owns which screen is visible and the currently-active mission (if any).
/// Feature view models call into the router to switch screens; the router
/// never reaches back into them.
final class AppRouter: ObservableObject {
    @Published var gameState: GameState = .map
    @Published var activeMission: MissionCoordinator?
}
