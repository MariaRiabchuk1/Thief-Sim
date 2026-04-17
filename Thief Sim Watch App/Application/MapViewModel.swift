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

    private var cancellables = Set<AnyCancellable>()

    init(session: GameSession) {
        self.session = session
        session.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
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
        session.selectDistrict(district.id)
        onStartMission?(district, bribe)
    }
    
    func didSelectDistrict(at index: Int) {
        selectedDistrictIndex = index
        session.selectDistrict(currentDistrict.id)
    }

    func selectDistrict(_ id: DistrictID) {
        if let index = session.districts.firstIndex(where: { $0.id == id }) {
            selectedDistrictIndex = index
            session.selectDistrict(id)
        }
    }

    func openShop() {
        onOpenShop?()
    }
}
