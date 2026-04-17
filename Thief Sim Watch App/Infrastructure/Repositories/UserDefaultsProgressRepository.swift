import Foundation

/// UserDefaults implementation of the ProgressRepository.
final class UserDefaultsProgressRepository: ProgressRepository {
    private let storageKey = "player_progress_blob"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func load() -> PlayerProgress? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(PlayerProgress.self, from: data)
        } catch {
            print("Failed to decode PlayerProgress: \(error)")
            return nil
        }
    }
    
    func save(_ progress: PlayerProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode PlayerProgress: \(error)")
        }
    }
}
