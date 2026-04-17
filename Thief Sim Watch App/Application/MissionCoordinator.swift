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
    
    @Published var isPaused: Bool = false

    let missionService: MissionService
    let hapticProvider: HapticProvider
    let audioProvider: AudioProvider
    let persistenceService: MissionPersistenceService

    private var cancellables = Set<AnyCancellable>()

    init(
        session: GameSession,
        router: AppRouter,
        district: District,
        bribeActive: Bool,
        missionService: MissionService = GameMissionService(),
        hapticProvider: HapticProvider = WatchHapticProvider(),
        audioProvider: AudioProvider = WatchAudioProvider(),
        persistenceService: MissionPersistenceService = .shared
    ) {
        self.session = session
        self.router = router
        self.district = district
        self.bribeActive = bribeActive
        self.missionService = missionService
        self.hapticProvider = hapticProvider
        self.audioProvider = audioProvider
        self.persistenceService = persistenceService
        
        session.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    /// Reconstructs a coordinator from a persistent snapshot.
    convenience init?(
        snapshot: ActiveMissionSnapshot,
        session: GameSession,
        router: AppRouter,
        missionService: MissionService = GameMissionService(),
        hapticProvider: HapticProvider = WatchHapticProvider(),
        audioProvider: AudioProvider = WatchAudioProvider(),
        persistenceService: MissionPersistenceService = .shared
    ) {
        guard let district = session.districts.first(where: { $0.id == snapshot.districtId }) else { return nil }
        
        self.init(
            session: session,
            router: router,
            district: district,
            bribeActive: snapshot.bribeActive,
            missionService: missionService,
            hapticProvider: hapticProvider,
            audioProvider: audioProvider,
            persistenceService: persistenceService
        )
        
        self.detectionLevel = snapshot.detectionLevel
        self.timeRemaining = snapshot.timeRemaining
        self.empActive = snapshot.empActive
        self.isTreasureLevel = snapshot.isTreasureLevel
        self.combination = snapshot.combination
        self.currentStep = snapshot.currentStep
        self.isPaused = true // Resume starts paused
    }

    var level: Int { session.level(of: district) }
    var minTolerance: Double { session.districts.last?.safeTolerance ?? 0.5 }
    var hasStethoscope: Bool { session.ownedUpgrades.contains(.stethoscope) }
    var hasLockpicks: Bool { session.ownedUpgrades.contains(.lockpicks) }

    func start() {
        let baseTime = district.timeLimit ?? 100
        timeRemaining = missionService.calculateTimeLimit(base: baseTime, bribeActive: bribeActive, level: level)
        isTreasureLevel = missionService.shouldBeTreasureLevel()
        combination = missionService.generateCombination(length: district.codeLength)
        router.gameState = .ventCrawl
        saveSnapshot()
    }

    func advance(to state: GameState) {
        router.gameState = state
        saveSnapshot()
    }

    func markCaught() {
        hapticProvider.play(.failure)
        audioProvider.play(.failThump)
        router.gameState = .caught
        persistenceService.clear()
    }

    func markSuccess() {
        audioProvider.play(.successChime)
        router.gameState = .success
        persistenceService.clear()
    }

    func useSmokeBomb() {
        guard session.consume(.smokeBomb) else { return }
        detectionLevel = 0.0
        hapticProvider.play(.retry)
        saveSnapshot()
    }

    func useEMP() {
        guard session.consume(.emp) else { return }
        empActive = true
        hapticProvider.play(.directionDown)
        router.gameState = .safeCracking
        saveSnapshot()
    }

    func increaseDetection(by amount: Double) {
        detectionLevel += amount
        if detectionLevel >= 1.0 {
            markCaught()
        } else {
            saveSnapshot()
        }
    }

    // Safe-cracking tick (1s).
    func handleSafePhaseTick() {
        guard !isPaused else { return }
        
        patrolTick += 1
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 0 {
                markCaught()
                return
            }
        }
        if detectionLevel > 0.2 && patrolTick % 2 == 0 { hapticProvider.play(.click) }
        handlePatrolLogic()
        
        // Save periodic snapshot during safe cracking
        if patrolTick % 5 == 0 {
            saveSnapshot()
        }
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
            // Patrol start chain: .stop + .failure
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.hapticProvider.play(.failure)
            }
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
        audioProvider.stopAll()
        router.activeMission = nil
        router.gameState = .map
        persistenceService.clear()
    }

    var rewardPreview: Int {
        isTreasureLevel ? district.reward * 2 : district.reward
    }
    
    func saveSnapshot() {
        let snapshot = ActiveMissionSnapshot(
            districtId: district.id,
            gameState: router.gameState,
            bribeActive: bribeActive,
            detectionLevel: detectionLevel,
            timeRemaining: timeRemaining,
            empActive: empActive,
            isTreasureLevel: isTreasureLevel,
            combination: combination,
            currentStep: currentStep
        )
        persistenceService.save(snapshot)
    }
}
