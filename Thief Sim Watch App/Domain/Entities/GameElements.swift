import Foundation

/// Types of obstacles in the vent crawl.
enum ObstacleType {
    case wall, enemy, turret
}

/// An obstacle in the vent crawl.
struct Obstacle: Identifiable, Equatable {
    let id = UUID()
    var x: Double
    var y: Double
    var width: Double
    var type: ObstacleType
    var speedX: Double = 0
    var lastShootTime: Double = 0
}

/// A bullet fired by a turret.
struct Bullet: Identifiable, Equatable {
    let id = UUID()
    var x: Double
    var y: Double
}
