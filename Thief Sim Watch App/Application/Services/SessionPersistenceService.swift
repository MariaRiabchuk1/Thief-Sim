import Foundation

/// DTO for persisting the entire player session.
struct GameSessionSnapshot: Codable {
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

/// Handles saving and loading the player's progression.
final class SessionPersistenceService {
    static let shared = SessionPersistenceService()
    
    private let sessionKey = "player_session_snapshot"
    private let userDefaults = UserDefaults.standard
    
    func save(_ snapshot: GameSessionSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            userDefaults.set(data, forKey: sessionKey)
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func load() -> GameSessionSnapshot? {
        guard let data = userDefaults.data(forKey: sessionKey) else { return nil }
        do {
            return try JSONDecoder().decode(GameSessionSnapshot.self, from: data)
        } catch {
            print("Failed to load session: \(error)")
            return nil
        }
    }
}
