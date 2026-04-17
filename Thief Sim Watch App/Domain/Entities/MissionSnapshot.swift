import Foundation

/// A persistent snapshot of an active mission for recovery across app restarts.
struct ActiveMissionSnapshot: Codable {
    let districtId: DistrictID
    let gameState: GameState
    let bribeActive: Bool
    let detectionLevel: Double
    let timeRemaining: Int
    let empActive: Bool
    let isTreasureLevel: Bool
    let combination: [Double]
    let currentStep: Int
}

/// Simple enum for game states that are recoverable.
enum RecoverableGameState: String, Codable {
    case ventCrawl
    case hacking
    case safeCracking
}

/// Mapping GameState to RecoverableGameState if applicable.
extension GameState {
    var asRecoverable: RecoverableGameState? {
        switch self {
        case .ventCrawl: return .ventCrawl
        case .hacking: return .hacking
        case .safeCracking: return .safeCracking
        default: return nil
        }
    }
    
    static func from(recoverable: RecoverableGameState) -> GameState {
        switch recoverable {
        case .ventCrawl: return .ventCrawl
        case .hacking: return .hacking
        case .safeCracking: return .safeCracking
        }
    }
}
