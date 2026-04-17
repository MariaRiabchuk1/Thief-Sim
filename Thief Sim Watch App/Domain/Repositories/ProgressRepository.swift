import Foundation

/// DTO for persisting the entire player session.
struct PlayerProgress: Codable {
    let totalMoney: Int
    let totalEarnings: Int
    let unlockedDistricts: Set<DistrictID>
    let ownedUpgrades: Set<UpgradeID>
    let ownedSkins: Set<SkinID>
    let ownedAccessories: Set<AccessoryID>
    let consumables: [UpgradeID: Int]
    let districtProgress: [DistrictID: Int]
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
