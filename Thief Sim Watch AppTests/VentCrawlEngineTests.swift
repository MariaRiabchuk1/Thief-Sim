import Testing
import Foundation
@testable import Thief_Sim_Watch_App

@Suite("VentCrawlEngine")
struct VentCrawlEngineTests {

    // MARK: Collision

    @Test("Player overlapping an obstacle's collision rect returns .caught")
    func collisionOnIntersect() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0.1
        state.lastSpawnProgress = state.progress
        state.playerX = 0.5
        state.obstacles = [
            Obstacle(
                x: 0.5,
                y: VentCrawlMetrics.playerCenterY,
                width: VentCrawlMetrics.enemyWidth,
                type: .enemy
            )
        ]

        let outcome = engine.step(state: &state, level: 0)

        #expect(outcome == .caught)
    }

    @Test("Player far from the only obstacle does not trigger .caught")
    func noCollisionWhenSeparated() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0.1
        state.lastSpawnProgress = state.progress
        state.playerX = 0.2
        state.obstacles = [
            Obstacle(
                x: 0.85,
                y: 0.1,
                width: VentCrawlMetrics.enemyWidth,
                type: .enemy
            )
        ]

        let outcome = engine.step(state: &state, level: 0)

        #expect(outcome == .ongoing)
    }

    @Test("A bullet at the player position returns .caught")
    func bulletHitIsCaught() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0.1
        state.lastSpawnProgress = state.progress
        state.playerX = 0.5
        state.bullets = [
            Bullet(x: 0.5, y: VentCrawlMetrics.playerCenterY)
        ]

        let outcome = engine.step(state: &state, level: 0)

        #expect(outcome == .caught)
    }

    // MARK: Spawn cadence

    @Test("Spawn interval shrinks as the district level increases")
    func spawnIntervalScalesWithLevel() {
        let level0 = VentCrawlMetrics.spawnInterval(level: 0)
        let level3 = VentCrawlMetrics.spawnInterval(level: 3)
        let level7 = VentCrawlMetrics.spawnInterval(level: 7)

        #expect(level0 > level3)
        #expect(level3 > level7)
        #expect(level7 >= 0.05) // clamp at floor
    }

    @Test("With a seeded RNG, the first spawn produces the same obstacle kind")
    func deterministicSpawnGivenSeededRNG() {
        // Step past the spawn threshold for level 0.
        let interval = VentCrawlMetrics.spawnInterval(level: 0)

        let engineA = GameVentCrawlEngine(rng: SeededRNG(seed: 42))
        var stateA = VentCrawlState()
        stateA.lastSpawnProgress = -interval * 2

        let engineB = GameVentCrawlEngine(rng: SeededRNG(seed: 42))
        var stateB = VentCrawlState()
        stateB.lastSpawnProgress = -interval * 2

        _ = engineA.step(state: &stateA, level: 0)
        _ = engineB.step(state: &stateB, level: 0)

        #expect(stateA.obstacles.count == stateB.obstacles.count)
        #expect(stateA.obstacles.first?.type == stateB.obstacles.first?.type)
    }

    // MARK: Finish

    @Test("Progress >= 1.0 returns .finished")
    func finishCondition() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0.9999
        state.lastSpawnProgress = state.progress

        let outcome = engine.step(state: &state, level: 0)

        #expect(outcome == .finished)
    }

    @Test("Progress advances by the expected amount per tick")
    func progressAdvances() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0
        state.lastSpawnProgress = 0

        _ = engine.step(state: &state, level: 0)

        let expected = VentCrawlMetrics.progressPerTick(level: 0)
        #expect(abs(state.progress - expected) < 1e-9)
    }

    // MARK: Prune

    @Test("Obstacles past the off-screen y are pruned")
    func offscreenObstaclesArePruned() {
        let engine = GameVentCrawlEngine(rng: SeededRNG(seed: 1))
        var state = VentCrawlState()
        state.progress = 0.1
        state.lastSpawnProgress = state.progress
        state.playerX = 0.2
        state.obstacles = [
            Obstacle(x: 0.9, y: VentCrawlMetrics.offscreenY + 0.01, width: VentCrawlMetrics.enemyWidth, type: .wall)
        ]

        _ = engine.step(state: &state, level: 0)

        #expect(state.obstacles.isEmpty)
    }
}

/// Deterministic RNG so spawn/position tests don't flake.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
