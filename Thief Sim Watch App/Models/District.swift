import Foundation

struct District: Identifiable {
    let id = UUID()
    let name: String
    let reward: Int
    let codeLength: Int
    let safeTolerance: Double
    let hackSpeed: Double
    let hasPatrol: Bool
    let timeLimit: Int?
}
