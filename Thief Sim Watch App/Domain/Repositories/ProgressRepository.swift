import Foundation

/// DTO for persisting the entire player session.
struct PlayerProgress: Codable {
    let totalMoney: Int
    let totalEarnings: Int
    let unlockedDistricts: Set<String>
    let ownedUpgrades: Set<UpgradeID>
    let ownedSkins: Set<String>
    let ownedAccessories: Set<String>
    let consumables: [UpgradeID: Int]
    let districtProgress: [String: Int]
    let currentSkinName: String
    let currentAccessoryName: String?
    let seenCoachMarks: Set<String>
}

/// Repository for managing player progression persistence.
protocol ProgressRepository {
    /// Loads the player progress from persistent storage.
    func load() -> PlayerProgress?
    
    /// Saves the player progress to persistent storage.
    func save(_ progress: PlayerProgress)
}
