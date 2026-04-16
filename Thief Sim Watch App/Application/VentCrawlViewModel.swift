import Foundation
import Combine
import CoreGraphics
import WatchKit

/// Drives the vent-crawl minigame.
///
/// Owns the player lane position, spawned obstacles/bullets, and per-frame
/// physics. Reads the shared mission snapshot from `MissionCoordinator` for
/// district-level tuning.
final class VentCrawlViewModel: ObservableObject {
    let coordinator: MissionCoordinator

    @Published var ventPosition: Double = 75
    @Published var ventDistance: Double = 0
    @Published var obstacles: [Obstacle] = []
    @Published var bullets: [Bullet] = []

    private var lastSpawnY: Double = -20
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: MissionCoordinator) {
        self.coordinator = coordinator
        coordinator.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var session: GameSession { coordinator.session }

    func tick() {
        ventDistance += 0.45

        for i in 0..<bullets.count { bullets[i].y += 5.5 }
        bullets.removeAll { $0.y > 160 }

        for i in 0..<obstacles.count {
            obstacles[i].y += 2.2
            if obstacles[i].type == .enemy {
                obstacles[i].x += obstacles[i].speedX
                if obstacles[i].x > 130 || obstacles[i].x < 20 { obstacles[i].speedX *= -1 }
            }
            if obstacles[i].type == .turret {
                if ventDistance - obstacles[i].lastShootTime > 20 {
                    bullets.append(Bullet(x: obstacles[i].x, y: obstacles[i].y + 5.0))
                    obstacles[i].lastShootTime = ventDistance
                }
            }

            let playerRect = CGRect(x: CGFloat(ventPosition - 6), y: 115, width: 12, height: 18)
            let obs = obstacles[i]
            let obsRect = CGRect(x: CGFloat(obs.x - obs.width/2.0), y: CGFloat(obs.y - 4.0), width: CGFloat(obs.width), height: 8.0)
            if playerRect.intersects(obsRect) {
                coordinator.markCaught()
                return
            }
        }

        for bullet in bullets {
            let playerRect = CGRect(x: CGFloat(ventPosition - 6), y: 115, width: 12, height: 18)
            if playerRect.contains(CGPoint(x: CGFloat(bullet.x), y: CGFloat(bullet.y))) {
                coordinator.markCaught()
                return
            }
        }

        obstacles.removeAll { $0.y > 160 }

        let spawnThreshold = 35.0 - Double(coordinator.level) * 2.0
        if ventDistance - lastSpawnY > spawnThreshold {
            spawnObstacle()
            lastSpawnY = ventDistance
        }

        let targetDistance = 100.0 + Double(coordinator.level) * 10.0
        if ventDistance >= targetDistance {
            coordinator.advance(to: .hacking)
            coordinator.hapticProvider.play(.success)
        }
    }

    private func spawnObstacle() {
        let rand = Int.random(in: 0...100)
        if rand < 30 {
            obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 15, type: .turret))
        } else if rand < 60 {
            let enemySpeed = 1.5 + Double(coordinator.level) * 0.2
            obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 20, type: .enemy, speedX: enemySpeed))
        } else {
            let side = Bool.random()
            obstacles.append(Obstacle(x: side ? 35 : 115, y: -10, width: 70, type: .wall))
        }
    }
}
