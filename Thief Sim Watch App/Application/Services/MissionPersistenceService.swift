import Foundation

/// Handles saving and loading mission snapshots to disk.
final class MissionPersistenceService {
    static let shared = MissionPersistenceService()
    
    private let snapshotKey = "active_mission_snapshot"
    private let userDefaults = UserDefaults.standard
    
    /// Saves the mission snapshot to persistent storage.
    func save(_ snapshot: ActiveMissionSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            userDefaults.set(data, forKey: snapshotKey)
        } catch {
            print("Failed to save mission snapshot: \(error)")
        }
    }
    
    /// Loads the mission snapshot from persistent storage.
    func load() -> ActiveMissionSnapshot? {
        guard let data = userDefaults.data(forKey: snapshotKey) else { return nil }
        do {
            return try JSONDecoder().decode(ActiveMissionSnapshot.self, from: data)
        } catch {
            print("Failed to load mission snapshot: \(error)")
            return nil
        }
    }
    
    /// Clears the saved mission snapshot.
    func clear() {
        userDefaults.removeObject(forKey: snapshotKey)
    }
}
