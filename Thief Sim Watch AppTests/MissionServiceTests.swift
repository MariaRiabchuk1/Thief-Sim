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

    @Test("shouldBeTreasureLevel produces identical results with the same seed")
    func deterministicTreasureLevel() {
        let serviceA = GameMissionService(rng: SeededRNG(seed: 456))
        let resultA = serviceA.shouldBeTreasureLevel()

        let serviceB = GameMissionService(rng: SeededRNG(seed: 456))
        let resultB = serviceB.shouldBeTreasureLevel()

        #expect(resultA == resultB)
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
