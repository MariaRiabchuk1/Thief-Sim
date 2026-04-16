import Foundation
import CoreGraphics

/// Pure game engine for the vent-crawl minigame.
///
/// Operates in a normalized coordinate system:
/// - horizontal lane position: `0.0` (left edge) to `1.0` (right edge)
/// - viewport y: `0.0` (top) to `1.0` (bottom); content off-screen at ±`0.05`
/// - mission progress: `0.0` (start) to `1.0` (finish); the engine signals
///   `.finished` when progress reaches 1.0
///
/// Views are responsible for mapping these ratios to pixels. No
/// SwiftUI or view-layer types are used here; `CGRect` is imported
/// purely as a geometry primitive.
struct VentCrawlState: Equatable {
    var playerX: Double = 0.5
    var progress: Double = 0
    var obstacles: [Obstacle] = []
    var bullets: [Bullet] = []
    var lastSpawnProgress: Double = -0.2
}

enum VentCrawlOutcome: Equatable {
    case ongoing
    case finished
    case caught
}

/// Tuning constants expressed as ratios of the viewport / mission length.
enum VentCrawlMetrics {
    // Player hit-box (centered on `playerX`, `playerCenterY`).
    static let playerWidth: Double = 0.08
    static let playerHeight: Double = 0.10
    static let playerCenterY: Double = 0.69

    // Crown-bound lane (clamped to keep the centered player sprite on-canvas).
    static let laneMin: Double = playerWidth / 2
    static let laneMax: Double = 1.0 - playerWidth / 2

    // Per-tick motion.
    static let obstacleFallPerTick: Double = 0.012
    static let bulletFallPerTick: Double = 0.031

    // Off-screen culling & spawn row.
    static let offscreenY: Double = 1.05
    static let spawnY: Double = -0.06

    // Enemy bounce bounds.
    static let enemyXMin: Double = 0.12
    static let enemyXMax: Double = 0.76

    // Spawn x range.
    static let spawnXMin: Double = 0.18
    static let spawnXMax: Double = 0.71

    // Wall parking spots.
    static let wallXLeft: Double = 0.21
    static let wallXRight: Double = 0.68

    // Drawn widths.
    static let turretWidth: Double = 0.088
    static let enemyWidth: Double = 0.118
    static let wallWidth: Double = 0.412

    // Collision rect is thinner than the drawn sprite on the y-axis.
    static let obstacleCollisionYOffset: Double = 0.022
    static let obstacleCollisionHeight: Double = 0.044

    // Turret shooting.
    static let turretBulletYOffset: Double = 0.028
    static let turretCooldown: Double = 0.2

    /// Progress advanced per tick. Mission target grows with level, so the
    /// same tick count yields less normalized progress.
    static func progressPerTick(level: Int) -> Double {
        0.45 / (100.0 + Double(level) * 10.0)
    }

    /// Spawn interval in progress units; tightens with level.
    static func spawnInterval(level: Int) -> Double {
        max(0.05, 0.35 - Double(level) * 0.02)
    }

    /// Enemy horizontal speed in lane-units per tick.
    static func enemyHorizontalSpeed(level: Int) -> Double {
        0.009 + Double(level) * 0.0012
    }
}

protocol VentCrawlEngine {
    func step(state: inout VentCrawlState, level: Int) -> VentCrawlOutcome
}

final class GameVentCrawlEngine: VentCrawlEngine {
    private var rng: any RandomNumberGenerator

    init(rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.rng = rng
    }

    func step(state: inout VentCrawlState, level: Int) -> VentCrawlOutcome {
        state.progress += VentCrawlMetrics.progressPerTick(level: level)

        for i in state.bullets.indices {
            state.bullets[i].y += VentCrawlMetrics.bulletFallPerTick
        }
        state.bullets.removeAll { $0.y > VentCrawlMetrics.offscreenY }

        for i in state.obstacles.indices {
            state.obstacles[i].y += VentCrawlMetrics.obstacleFallPerTick

            if state.obstacles[i].type == .enemy {
                state.obstacles[i].x += state.obstacles[i].speedX
                if state.obstacles[i].x > VentCrawlMetrics.enemyXMax || state.obstacles[i].x < VentCrawlMetrics.enemyXMin {
                    state.obstacles[i].speedX *= -1
                }
            }

            if state.obstacles[i].type == .turret {
                if state.progress - state.obstacles[i].lastShootTime > VentCrawlMetrics.turretCooldown {
                    let bullet = Bullet(
                        x: state.obstacles[i].x,
                        y: state.obstacles[i].y + VentCrawlMetrics.turretBulletYOffset
                    )
                    state.bullets.append(bullet)
                    state.obstacles[i].lastShootTime = state.progress
                }
            }
        }

        let playerRect = Self.playerRect(x: state.playerX)
        for obs in state.obstacles {
            if playerRect.intersects(Self.obstacleCollisionRect(for: obs)) {
                return .caught
            }
        }
        for bullet in state.bullets {
            if playerRect.contains(CGPoint(x: bullet.x, y: bullet.y)) {
                return .caught
            }
        }

        state.obstacles.removeAll { $0.y > VentCrawlMetrics.offscreenY }

        if state.progress - state.lastSpawnProgress > VentCrawlMetrics.spawnInterval(level: level) {
            state.obstacles.append(spawnObstacle(level: level))
            state.lastSpawnProgress = state.progress
        }

        if state.progress >= 1.0 { return .finished }
        return .ongoing
    }

    private func spawnObstacle(level: Int) -> Obstacle {
        let rand = Int.random(in: 0...100, using: &rng)
        if rand < 30 {
            let x = Double.random(in: VentCrawlMetrics.spawnXMin...VentCrawlMetrics.spawnXMax, using: &rng)
            return Obstacle(x: x, y: VentCrawlMetrics.spawnY, width: VentCrawlMetrics.turretWidth, type: .turret)
        } else if rand < 60 {
            let x = Double.random(in: VentCrawlMetrics.spawnXMin...VentCrawlMetrics.spawnXMax, using: &rng)
            return Obstacle(
                x: x,
                y: VentCrawlMetrics.spawnY,
                width: VentCrawlMetrics.enemyWidth,
                type: .enemy,
                speedX: VentCrawlMetrics.enemyHorizontalSpeed(level: level)
            )
        } else {
            let left = Bool.random(using: &rng)
            return Obstacle(
                x: left ? VentCrawlMetrics.wallXLeft : VentCrawlMetrics.wallXRight,
                y: VentCrawlMetrics.spawnY,
                width: VentCrawlMetrics.wallWidth,
                type: .wall
            )
        }
    }

    static func playerRect(x: Double) -> CGRect {
        CGRect(
            x: x - VentCrawlMetrics.playerWidth / 2,
            y: VentCrawlMetrics.playerCenterY - VentCrawlMetrics.playerHeight / 2,
            width: VentCrawlMetrics.playerWidth,
            height: VentCrawlMetrics.playerHeight
        )
    }

    static func obstacleCollisionRect(for obstacle: Obstacle) -> CGRect {
        CGRect(
            x: obstacle.x - obstacle.width / 2,
            y: obstacle.y - VentCrawlMetrics.obstacleCollisionYOffset,
            width: obstacle.width,
            height: VentCrawlMetrics.obstacleCollisionHeight
        )
    }
}
