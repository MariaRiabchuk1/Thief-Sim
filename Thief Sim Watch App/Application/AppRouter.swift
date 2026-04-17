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
    
    var onDeepLinkDistrict: ((DistrictID) -> Void)?

    /// Handles deep linking from the complication.
    /// Expected format: thiefsim://district/{id}
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "thiefsim" else { return }
        
        let pathComponents = url.pathComponents
        if pathComponents.contains("district"), let districtRaw = pathComponents.last {
            if let districtId = DistrictID(rawValue: districtRaw) {
                // If in a mission, we might want to ignore or prompt, 
                // but requirements say "opens the app and navigates directly".
                // We'll reset to map and notify the view model.
                activeMission = nil
                gameState = .map
                onDeepLinkDistrict?(districtId)
            }
        }
    }
}
