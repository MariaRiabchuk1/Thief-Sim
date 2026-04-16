import Foundation

/// Types of obstacles in the vent crawl.
enum ObstacleType {
    case wall, enemy, turret
}

/// An obstacle in the vent crawl.
///
/// `id` is assigned by the spawner (a monotonic counter on the engine
/// state), so two obstacles with the same position still get distinct
/// identities for `ForEach` diffing, and respawning doesn't reuse ids.
struct Obstacle: Identifiable, Equatable {
    let id: Int
    var x: Double
    var y: Double
    var width: Double
    var type: ObstacleType
    var speedX: Double = 0
    var lastShootTime: Double = 0
}

/// A bullet fired by a turret.
struct Bullet: Identifiable, Equatable {
    let id: Int
    var x: Double
    var y: Double
}
