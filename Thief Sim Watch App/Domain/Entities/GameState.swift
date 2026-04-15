import Foundation

/// Possible game states.
enum GameState: Equatable {
    case map
    case shop
    case ventCrawl
    case hacking
    case safeCracking
    case caught
    case success
}
