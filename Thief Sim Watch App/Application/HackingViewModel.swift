import Foundation
import Combine
import WatchKit

/// Drives the alarm-hacking minigame.
final class HackingViewModel: ObservableObject {
    let coordinator: MissionCoordinator

    @Published var hackPosition: Double = 0.0
    @Published var hackDirection: Double = 1.0

    private var cancellables = Set<AnyCancellable>()

    init(coordinator: MissionCoordinator) {
        self.coordinator = coordinator
        coordinator.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var session: GameSession { coordinator.session }

    func tick() {
        let speedBoost = Double(coordinator.level) * 0.5
        hackPosition += (coordinator.district.hackSpeed + speedBoost) * hackDirection
        if hackPosition > 55 || hackPosition < -55 { hackDirection *= -1 }
    }

    func performHack() {
        if abs(hackPosition) < 15 {
            coordinator.hapticProvider.play(.success)
            coordinator.advance(to: .safeCracking)
        } else {
            coordinator.hapticProvider.play(.failure)
            coordinator.increaseDetection(by: 0.3)
        }
    }

    func useEMP() {
        coordinator.useEMP()
    }
}
