import Foundation
import Combine
import WatchKit

/// Drives the alarm-hacking minigame.
final class HackingViewModel: ObservableObject {
    let coordinator: MissionCoordinator
    let clock: GameClock

    @Published var hackPosition: Double = 0.0
    @Published var hackDirection: Double = 1.0

    private var cancellables = Set<AnyCancellable>()

    init(coordinator: MissionCoordinator, clock: GameClock = SystemGameClock()) {
        self.coordinator = coordinator
        self.clock = clock
        coordinator.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var session: GameSession { coordinator.session }

    func tick() {
        guard !coordinator.isPaused else {
            coordinator.audioProvider.stopAll()
            return
        }
        
        let speedBoost = Double(coordinator.level) * 0.5
        // Normalize speed to the -1.0...1.0 range. 
        // Original was roughly -55...55 with speed ~2-6. 
        let normalizedSpeed = (coordinator.district.hackSpeed + speedBoost) / 100.0
        
        hackPosition += normalizedSpeed * hackDirection
        if hackPosition > 1.0 || hackPosition < -1.0 {
            hackDirection *= -1
            hackPosition = max(-1.0, min(1.0, hackPosition))
        }
        
        // Diegetic Audio: Alarm whine if outside green zone.
        // Success zone is abs(hackPosition) < 0.25
        if abs(hackPosition) >= 0.25 {
            coordinator.audioProvider.play(.alarmWhine)
        } else {
            // In a more complex implementation, we'd only stop if it was playing
            // but stopAll() or a specific stopSound() is safer for now.
        }
    }

    func performHack() {
        // Success if within roughly 25% of center (original 15/55 ≈ 0.27)
        if abs(hackPosition) < 0.25 {
            coordinator.hapticProvider.play(.start)
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
