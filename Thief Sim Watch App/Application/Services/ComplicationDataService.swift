import Foundation
import SwiftUI
import WidgetKit

/// Persistence service for sharing game state with the watch complication.
///
/// Complications in watchOS 10+ are driven by WidgetKit, and while we're currently
/// in the same target, we use a shared UserDefaults suite (or the standard one)
/// to ensure the TimelineProvider always sees the latest balance and district.
final class ComplicationDataService {
    static let shared = ComplicationDataService()
    
    private let suiteName = "group.com.mariariabchuk.thiefsim"
    private let userDefaults: UserDefaults?
    
    private let balanceKey = "complication.balance"
    private let districtKey = "complication.district"
    
    init() {
        // We try to use the App Group suite. If it's not configured yet, 
        // fallback to standard so the code doesn't crash, but it might not 
        // update the complication if it's in a separate process.
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }
    
    /// Persists the player's status for the complication.
    func save(balance: Int, districtId: DistrictID) {
        userDefaults?.set(balance, forKey: balanceKey)
        userDefaults?.set(districtId.rawValue, forKey: districtKey)
        
        // Request a timeline reload for all complications.
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Loads the persisted status for the complication provider.
    func load() -> (balance: Int, districtId: DistrictID) {
        let balance = userDefaults?.integer(forKey: balanceKey) ?? 0
        let districtRaw = userDefaults?.string(forKey: districtKey) ?? DistrictID.outskirts.rawValue
        let districtId = DistrictID(rawValue: districtRaw) ?? .outskirts
        return (balance, districtId)
    }
}
