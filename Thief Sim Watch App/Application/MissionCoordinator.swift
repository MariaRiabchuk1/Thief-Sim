import Foundation
import Combine
import WatchKit

/// Owns the state shared across every phase of a single mission.
///
/// Minigame-private state (crown, obstacles, needle) lives on the per-phase
/// view models. What stays here: the district snapshot, detection level,
/// remaining time, patrol cycle, lock state, and the combination / step the
/// safe-cracking phase consumes.
final class MissionCoordinator: ObservableObject {
    let session: GameSession
    let router: AppRouter
    let district: District
    let bribeActive: Bool

    @Published var detectionLevel: Double = 0.0
    @Published var timeRemaining: Int = 0
    @Published var empActive: Bool = false
    @Published var isTreasureLevel: Bool = false
    @Published var isPatrolActive: Bool = false
    @Published var isPatrolWarning: Bool = false
    @Published var patrolTick: Int = 0
    @Published var isLockStuck: Bool = false
    @Published var stuckProgress: Int = 0
    @Published var combination: [Double] = []
    @Published var currentStep: Int = 0

    let missionService: MissionService
    let hapticProvider: HapticProvider

    private var cancellables = Set<AnyCancellable>()

    init(
        session: GameSession,
        router: AppRouter,
        district: District,
        bribeActive: Bool,
        missionService: MissionService = GameMissionService(),
        hapticProvider: HapticProvider = WatchHapticProvider()
    ) {
        self.session = session
        self.router = router
        self.district = district
        self.bribeActive = bribeActive
        self.missionService = missionService
        self.hapticProvider = hapticProvider
        session.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var level: Int { session.level(of: district) }
    var minTolerance: Double { session.districts.last?.safeTolerance ?? 0.5 }
    var hasStethoscope: Bool { session.ownedUpgrades.contains("Стетоскоп") }
    var hasLockpicks: Bool { session.ownedUpgrades.contains("Відмички") }

    func start() {
        let baseTime = district.timeLimit ?? 100
        timeRemaining = missionService.calculateTimeLimit(base: baseTime, bribeActive: bribeActive, level: level)
        isTreasureLevel = missionService.shouldBeTreasureLevel()
        combination = missionService.generateCombination(length: district.codeLength)
        router.gameState = .ventCrawl
    }

    func advance(to state: GameState) {
        router.gameState = state
    }

    func markCaught() {
        hapticProvider.play(.failure)
        router.gameState = .caught
    }

    func markSuccess() {
        router.gameState = .success
    }

    func useSmokeBomb() {
        guard session.consume("Дим. шашка") else { return }
        detectionLevel = 0.0
        hapticProvider.play(.success)
    }

    func useEMP() {
        guard session.consume("ЕМІ") else { return }
        empActive = true
        hapticProvider.play(.success)
        router.gameState = .safeCracking
    }

    func increaseDetection(by amount: Double) {
        detectionLevel += amount
        if detectionLevel >= 1.0 {
            markCaught()
        }
    }

    // Safe-cracking tick (1s).
    func handleSafePhaseTick() {
        patrolTick += 1
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 0 {
                router.gameState = .caught
                return
            }
        }
        if detectionLevel > 0.2 && patrolTick % 2 == 0 { hapticProvider.play(.click) }
        handlePatrolLogic()
    }

    private func handlePatrolLogic() {
        guard district.hasPatrol, !empActive else { return }
        if !isPatrolActive && !isPatrolWarning {
            if Int.random(in: 0...100) > 80 {
                isPatrolWarning = true
                hapticProvider.play(.directionUp)
            }
        } else if isPatrolWarning {
            isPatrolWarning = false
            isPatrolActive = true
            hapticProvider.play(.stop)
        } else if isPatrolActive {
            isPatrolActive = false
            hapticProvider.play(.directionDown)
        }
    }

    func finish(success: Bool) {
        session.applyUpkeep()
        if success {
            let reward = isTreasureLevel ? district.reward * 2 : district.reward
            session.addReward(reward)
            session.advanceProgress(in: district)
        } else {
            session.halveMoney()
        }
        router.activeMission = nil
        router.gameState = .map
    }

    var rewardPreview: Int {
        isTreasureLevel ? district.reward * 2 : district.reward
    }
}
