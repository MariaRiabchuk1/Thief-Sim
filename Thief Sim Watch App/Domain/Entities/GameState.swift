import Foundation

/// Possible game states.
enum GameState: String, Codable, Equatable {
    case map
    case shop
    case ventCrawl
    case hacking
    case safeCracking
    case caught
    case success
}
