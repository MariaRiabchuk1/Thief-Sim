import SwiftUI
import Combine

/// Drives the safe-cracking minigame.
///
/// Owns the crown-dial state and the resonance visual, plus the per-input
/// feedback loop. Reads the combination/step/patrol/detection from the
/// shared `MissionCoordinator`.
final class SafeCrackingViewModel: ObservableObject {
    let coordinator: MissionCoordinator

    @Published var crownValue: Double = 50
    @Published var lastFeedbackValue: Double = 50
    @Published var resonanceAlpha: Double = 0

    private var cancellables = Set<AnyCancellable>()

    init(coordinator: MissionCoordinator) {
        self.coordinator = coordinator
        coordinator.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var session: GameSession { coordinator.session }

    func handleSafeInput(_ value: Double) {
        let tolerance = coordinator.missionService.calculateScaledTolerance(
            base: coordinator.district.safeTolerance,
            bribeActive: coordinator.bribeActive,
            level: coordinator.level,
            minTolerance: coordinator.minTolerance
        )

        let target = coordinator.combination.isEmpty
            ? 0
            : (coordinator.currentStep < coordinator.combination.count ? coordinator.combination[coordinator.currentStep] : 0)
        let distance = abs(value - target)
        let boost = coordinator.hasStethoscope ? 1.5 : 1.0

        withAnimation(.linear(duration: 0.1)) {
            resonanceAlpha = max(0, 1.0 - (distance / (12.0 * boost)))
        }

        if floor(value) != floor(lastFeedbackValue) {
            if coordinator.isPatrolActive {
                coordinator.detectionLevel += 0.4
                coordinator.hapticProvider.play(.failure)
            } else if distance <= tolerance * boost {
                coordinator.hapticProvider.play(.notification)
            } else {
                coordinator.hapticProvider.play(.click)
            }
            lastFeedbackValue = value
        }
        if coordinator.detectionLevel >= 1.0 {
            coordinator.markCaught()
        }
    }

    func tryCrackSafe() {
        if coordinator.isPatrolActive || coordinator.isLockStuck { return }
        if coordinator.combination.isEmpty || coordinator.currentStep >= coordinator.combination.count { return }

        let tolerance = coordinator.missionService.calculateScaledTolerance(
            base: coordinator.district.safeTolerance,
            bribeActive: coordinator.bribeActive,
            level: coordinator.level,
            minTolerance: coordinator.minTolerance
        )

        let boost = coordinator.hasStethoscope ? 1.5 : 1.0

        if abs(crownValue - coordinator.combination[coordinator.currentStep]) <= tolerance * boost {
            coordinator.hapticProvider.play(.success)
            coordinator.currentStep += 1
            if coordinator.currentStep == coordinator.combination.count {
                coordinator.markSuccess()
            }
        } else {
            coordinator.hapticProvider.play(.failure)
            let penalty = coordinator.hasLockpicks ? 0.15 : 0.4
            coordinator.increaseDetection(by: penalty)
            coordinator.currentStep = 0
        }
    }

    func tapStuckLock() {
        coordinator.stuckProgress += 1
        if coordinator.stuckProgress >= 5 {
            coordinator.isLockStuck = false
            coordinator.stuckProgress = 0
        }
    }

    func useSmokeBomb() {
        coordinator.useSmokeBomb()
    }
}
