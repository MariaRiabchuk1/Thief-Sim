import Foundation
import Combine

/// Drives the district-selection screen.
///
/// Owns map-scoped state (which district is focused, whether a bribe has
/// been paid for the next run). Delegates money/unlock mutations to
/// `GameSession` and notifies the app to start missions / open shop via
/// closures wired up by the container.
final class MapViewModel: ObservableObject {
    let session: GameSession

    @Published var selectedDistrictIndex: Int = 0
    @Published var bribeActive: Bool = false

    var onStartMission: ((District, Bool) -> Void)?
    var onOpenShop: (() -> Void)?

    init(session: GameSession) {
        self.session = session
    }

    var currentDistrict: District { session.districts[selectedDistrictIndex] }
    var currentDistrictLevel: Int { session.level(of: currentDistrict) }
    var isCurrentDistrictUnlocked: Bool { session.unlockedDistricts.contains(currentDistrict.name) }

    func unlockDistrict(_ district: District) {
        session.unlockDistrict(district)
    }

    func toggleBribe() {
        if bribeActive {
            bribeActive = false
        } else if session.payBribe(for: currentDistrict) {
            bribeActive = true
        }
    }

    func startMission() {
        let district = currentDistrict
        let bribe = bribeActive
        bribeActive = false
        onStartMission?(district, bribe)
    }

    func openShop() {
        onOpenShop?()
    }
}
