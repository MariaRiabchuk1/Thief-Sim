import Foundation

/// A district where missions can be performed.
struct District: Identifiable, Equatable {
    let id: DistrictID
    let name: String
    let reward: Int
    let codeLength: Int
    let safeTolerance: Double
    let hackSpeed: Double
    let hasPatrol: Bool
    let timeLimit: Int?
    let unlockPrice: Int
    let unlockSteps: Int
}
