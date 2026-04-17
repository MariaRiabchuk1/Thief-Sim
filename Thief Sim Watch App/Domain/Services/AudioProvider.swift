import Foundation

/// Defines the types of sound effects available in the game.
enum GameSound {
    /// A short mechanical tick for the safe dial.
    case dialTick(pitch: Float)
    /// A chime for successful action.
    case successChime
    /// An alarm whine for hacking errors.
    case alarmWhine
    /// A heavy thump for failure/getting caught.
    case failThump
}

/// Provides audio feedback functionality.
protocol AudioProvider {
    /// Plays a specific game sound.
    func play(_ sound: GameSound)
    
    /// Stops any looping or long-running sounds (like alarmWhine).
    func stopAll()
}
