import Testing
import Foundation
@testable import Thief_Sim_Watch_App

@Suite("MissionService")
struct MissionServiceTests {

    @Test("generateCombination produces identical results with the same seed")
    func deterministicCombination() {
        let serviceA = GameMissionService(rng: SeededRNG(seed: 123))
        let comboA = serviceA.generateCombination(length: 5)

        let serviceB = GameMissionService(rng: SeededRNG(seed: 123))
        let comboB = serviceB.generateCombination(length: 5)

        #expect(comboA == comboB)
        #expect(comboA.count == 5)
    }

    @Test("generateCombination produces rounded values between 10 and 90")
    func combinationValueRange() {
        let service = GameMissionService()
        let combo = service.generateCombination(length: 100)
        
        for value in combo {
            #expect(value >= 10 && value <= 90)
            #expect(value == value.rounded())
        }
    }

    @Test("shouldBeTreasureLevel produces identical results with the same seed")
    func deterministicTreasureLevel() {
        let serviceA = GameMissionService(rng: SeededRNG(seed: 456))
        let resultA = serviceA.shouldBeTreasureLevel()

        let serviceB = GameMissionService(rng: SeededRNG(seed: 456))
        let resultB = serviceB.shouldBeTreasureLevel()

        #expect(resultA == resultB)
    }

    @Test("Tolerance decreases as level increases but respects minimum floor")
    func toleranceScaling() {
        let service = GameMissionService()
        let base = 3.5
        let minT = 1.0
        
        let level0 = service.calculateScaledTolerance(base: base, bribeActive: false, level: 0, minTolerance: minT)
        let level1 = service.calculateScaledTolerance(base: base, bribeActive: false, level: 1, minTolerance: minT)
        let level20 = service.calculateScaledTolerance(base: base, bribeActive: false, level: 20, minTolerance: minT)
        
        #expect(level0 == 3.5)
        #expect(level1 < level0)
        #expect(level20 == minT + 0.1) // Clamped to floor
    }

    @Test("Bribe adds +1.0 to tolerance and +20s to time limit")
    func bribeEffects() {
        let service = GameMissionService()
        
        // Tolerance
        let normalT = service.calculateScaledTolerance(base: 2.0, bribeActive: false, level: 0, minTolerance: 0.5)
        let bribeT = service.calculateScaledTolerance(base: 2.0, bribeActive: true, level: 0, minTolerance: 0.5)
        #expect(bribeT == normalT + 1.0)
        
        // Time Limit
        let normalTime = service.calculateTimeLimit(base: 60, bribeActive: false, level: 0)
        let bribeTime = service.calculateTimeLimit(base: 60, bribeActive: true, level: 0)
        #expect(bribeTime == normalTime + 20)
    }
    
    @Test("Time limit decreases as level increases")
    func timeLimitScaling() {
        let service = GameMissionService()
        let base = 60
        
        let level0 = service.calculateTimeLimit(base: base, bribeActive: false, level: 0)
        let level5 = service.calculateTimeLimit(base: base, bribeActive: false, level: 5)
        
        #expect(level0 == 60)
        #expect(level5 == 50) // 60 - (5 * 2)
    }
}

/// Deterministic RNG for testing.
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
