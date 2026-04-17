import Foundation

/// DTO for persisting the entire player session.
/// Uses String for IDs in storage to be robust against enum changes.
struct PlayerProgress: Codable {
    let totalMoney: Int
    let totalEarnings: Int
    let unlockedDistricts: [String]
    let ownedUpgrades: [String]
    let ownedSkins: [String]
    let ownedAccessories: [String]
    let consumables: [String: Int]
    let districtProgress: [String: Int]
    let currentSkinName: String
    let currentAccessoryName: String?
    let seenCoachMarks: [String]
}

/// Repository for managing player progression persistence.
protocol ProgressRepository {
    func load() -> PlayerProgress?
    func save(_ progress: PlayerProgress)
}
