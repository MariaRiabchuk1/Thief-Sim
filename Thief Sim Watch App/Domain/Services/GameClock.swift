import Foundation

/// Abstraction for time-based ticking to allow manual advancement in tests.
protocol GameClock {
    /// Suspends the current task for the given duration.
    func sleep(seconds: Double) async throws
    
    /// Returns the current time in seconds.
    var now: Double { get }
}

/// Real implementation using ContinuousClock.
final class SystemGameClock: GameClock {
    private let clock = ContinuousClock()
    
    func sleep(seconds: Double) async throws {
        try await Task.sleep(until: .now + .seconds(seconds), clock: clock)
    }
    
    var now: Double {
        // Return a stable time reference if needed, but for ticking relative sleep is enough.
        Date().timeIntervalSinceReferenceDate
    }
}
