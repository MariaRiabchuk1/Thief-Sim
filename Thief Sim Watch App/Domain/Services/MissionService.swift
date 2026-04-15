import Foundation

/// Logic for game missions and challenges.
protocol MissionService {
    func calculateScaledTolerance(base: Double, bribeActive: Bool, level: Int, minTolerance: Double) -> Double
    func calculateTimeLimit(base: Int, bribeActive: Bool, level: Int) -> Int
    func shouldBeTreasureLevel() -> Bool
    func generateCombination(length: Int) -> [Double]
}

class GameMissionService: MissionService {
    func calculateScaledTolerance(base: Double, bribeActive: Bool, level: Int, minTolerance: Double) -> Double {
        var tolerance = base
        if bribeActive { tolerance += 1.0 }
        let reduction = Double(level) * 0.15
        return max(tolerance - reduction, minTolerance + 0.1)
    }
    
    func calculateTimeLimit(base: Int, bribeActive: Bool, level: Int) -> Int {
        (bribeActive ? base + 20 : base) - (level * 2)
    }
    
    func shouldBeTreasureLevel() -> Bool {
        Int.random(in: 0...100) < 15
    }
    
    func generateCombination(length: Int) -> [Double] {
        (0..<length).map { _ in Double.random(in: 10...90).rounded() }
    }
}
