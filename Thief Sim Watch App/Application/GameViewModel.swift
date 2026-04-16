import SwiftUI
import Combine

/// Coordinates the mission flow and the three minigame phases.
///
/// Progression lives on `GameSession`. Map- and shop-scoped state live on
/// `MapViewModel` / `ShopViewModel`. What stays here: the current game
/// screen, the active-mission snapshot, and all per-mission / per-minigame
/// state (detection, patrol, dial, obstacles, etc.).
class GameViewModel: ObservableObject {
    let session: GameSession

    // Dependencies
    private let missionService: MissionService
    private let hapticProvider: HapticProvider
    private var sessionCancellable: AnyCancellable?

    // App State
    @Published var gameState: GameState = .map

    // Active Mission
    @Published var activeDistrict: District?
    @Published var bribeActive = false
    @Published var detectionLevel: Double = 0.0
    @Published var timeRemaining: Int = 0
    @Published var empActive = false
    @Published var isTreasureLevel = false
    @Published var isLockStuck = false
    @Published var stuckProgress = 0

    // Minigame State
    @Published var ventPosition: Double = 75.0
    @Published var ventDistance: Double = 0.0
    @Published var obstacles: [Obstacle] = []
    @Published var bullets: [Bullet] = []
    @Published var hackPosition: Double = 0.0
    @Published var hackDirection: Double = 1.0
    @Published var combination: [Double] = []
    @Published var currentStep = 0
    @Published var crownValue: Double = 50.0
    @Published var lastFeedbackValue: Double = 50.0
    @Published var resonanceAlpha: Double = 0.0
    @Published var isPatrolActive = false
    @Published var isPatrolWarning = false
    @Published var patrolTick = 0

    private var lastSpawnY: Double = -20.0

    init(
        session: GameSession = GameSession(),
        missionService: MissionService = GameMissionService(),
        hapticProvider: HapticProvider = WatchHapticProvider()
    ) {
        self.session = session
        self.missionService = missionService
        self.hapticProvider = hapticProvider
        self.sessionCancellable = session.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var currentDistrict: District? { activeDistrict }
    var currentDistrictLevel: Int {
        guard let d = activeDistrict else { return 0 }
        return session.level(of: d)
    }

    // Screen Routing
    func openShop() {
        gameState = .shop
    }

    func closeShop() {
        gameState = .map
    }

    // Mission Flow
    func startMission(district: District, bribeActive: Bool) {
        activeDistrict = district
        self.bribeActive = bribeActive
        detectionLevel = 0.0; empActive = false; isPatrolActive = false; isPatrolWarning = false
        patrolTick = 0; currentStep = 0; crownValue = 50.0; lastFeedbackValue = 50.0

        let level = session.level(of: district)
        let baseTime = district.timeLimit ?? 100
        timeRemaining = missionService.calculateTimeLimit(base: baseTime, bribeActive: bribeActive, level: level)

        isTreasureLevel = missionService.shouldBeTreasureLevel()
        ventDistance = 0; ventPosition = 75; obstacles = []; bullets = []; lastSpawnY = -20.0
        combination = missionService.generateCombination(length: district.codeLength)
        gameState = .ventCrawl
    }

    func finishMission(success: Bool) {
        session.applyUpkeep()
        if let district = activeDistrict {
            if success {
                let reward = isTreasureLevel ? district.reward * 2 : district.reward
                session.addReward(reward)
                session.advanceProgress(in: district)
            } else {
                session.halveMoney()
            }
        }
        bribeActive = false
        activeDistrict = nil
        gameState = .map
    }

    // Game Ticks
    func handleFastTick() {
        if gameState == .ventCrawl {
            handleVentCrawlTick()
        } else if gameState == .hacking {
            handleHackingTick()
        }
    }

    func handleGlobalTick() {
        guard gameState == .safeCracking else { return }
        patrolTick += 1
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 0 { gameState = .caught }
        }
        if detectionLevel > 0.2 && patrolTick % 2 == 0 { hapticProvider.play(.click) }
        handlePatrolLogic()
    }

    private func handleHackingTick() {
        guard let district = activeDistrict else { return }
        let speedBoost = Double(currentDistrictLevel) * 0.5
        hackPosition += (district.hackSpeed + speedBoost) * hackDirection
        if hackPosition > 55 || hackPosition < -55 { hackDirection *= -1 }
    }

    private func handleVentCrawlTick() {
        guard activeDistrict != nil else { return }
        ventDistance += 0.45
        // Update bullets
        for i in 0..<bullets.count { bullets[i].y += 5.5 }
        bullets.removeAll { $0.y > 160 }

        // Update obstacles
        for i in 0..<obstacles.count {
            obstacles[i].y += 2.2
            if obstacles[i].type == .enemy {
                obstacles[i].x += obstacles[i].speedX
                if obstacles[i].x > 130 || obstacles[i].x < 20 { obstacles[i].speedX *= -1 }
            }
            if obstacles[i].type == .turret {
                if ventDistance - obstacles[i].lastShootTime > 20 {
                    bullets.append(Bullet(x: obstacles[i].x, y: obstacles[i].y + 5.0))
                    obstacles[i].lastShootTime = ventDistance
                }
            }

            let playerRect = CGRect(x: CGFloat(ventPosition - 6), y: 115, width: 12, height: 18)
            let obs = obstacles[i]
            let obsRect = CGRect(x: CGFloat(obs.x - obs.width/2.0), y: CGFloat(obs.y - 4.0), width: CGFloat(obs.width), height: 8.0)
            if playerRect.intersects(obsRect) { failMission() }
        }

        for bullet in bullets {
            let playerRect = CGRect(x: CGFloat(ventPosition - 6), y: 115, width: 12, height: 18)
            if playerRect.contains(CGPoint(x: CGFloat(bullet.x), y: CGFloat(bullet.y))) { failMission() }
        }

        obstacles.removeAll { $0.y > 160 }

        let spawnThreshold = 35.0 - Double(currentDistrictLevel) * 2.0
        if ventDistance - lastSpawnY > spawnThreshold {
            spawnObstacle()
            lastSpawnY = ventDistance
        }

        let targetDistance = 100.0 + Double(currentDistrictLevel) * 10.0
        if ventDistance >= targetDistance {
            gameState = .hacking
            hapticProvider.play(.success)
        }
    }

    private func spawnObstacle() {
        let rand = Int.random(in: 0...100)
        if rand < 30 {
            obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 15, type: .turret))
        } else if rand < 60 {
            let enemySpeed = 1.5 + Double(currentDistrictLevel) * 0.2
            obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 20, type: .enemy, speedX: enemySpeed))
        } else {
            let side = Bool.random()
            obstacles.append(Obstacle(x: side ? 35 : 115, y: -10, width: 70, type: .wall))
        }
    }

    // Hacking Logic
    func performHack() {
        if abs(hackPosition) < 15 {
            hapticProvider.play(.success)
            gameState = .safeCracking
        } else {
            hapticProvider.play(.failure)
            detectionLevel += 0.3
            if detectionLevel >= 1.0 { gameState = .caught }
        }
    }

    func useEMP() {
        guard session.consume("ЕМІ") else { return }
        empActive = true
        gameState = .safeCracking
        hapticProvider.play(.success)
    }

    // Safe Cracking Logic
    func handleSafeInput(_ value: Double) {
        guard let district = activeDistrict else { return }
        let tolerance = missionService.calculateScaledTolerance(
            base: district.safeTolerance,
            bribeActive: bribeActive,
            level: currentDistrictLevel,
            minTolerance: session.districts.last?.safeTolerance ?? 0.5
        )

        let target = combination.isEmpty ? 0 : (currentStep < combination.count ? combination[currentStep] : 0)
        let distance = abs(value - target)
        let boost = session.ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0

        withAnimation(.linear(duration: 0.1)) {
            resonanceAlpha = max(0, 1.0 - (distance / (12.0 * boost)))
        }

        if floor(value) != floor(lastFeedbackValue) {
            if isPatrolActive {
                detectionLevel += 0.4
                hapticProvider.play(.failure)
            } else {
                if distance <= tolerance * boost {
                    hapticProvider.play(.notification)
                } else {
                    hapticProvider.play(.click)
                }
            }
            lastFeedbackValue = value
        }
        if detectionLevel >= 1.0 { gameState = .caught }
    }

    func tryCrackSafe() {
        guard let district = activeDistrict else { return }
        if isPatrolActive || isLockStuck || combination.isEmpty || currentStep >= combination.count { return }

        let tolerance = missionService.calculateScaledTolerance(
            base: district.safeTolerance,
            bribeActive: bribeActive,
            level: currentDistrictLevel,
            minTolerance: session.districts.last?.safeTolerance ?? 0.5
        )

        let boost = session.ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0

        if abs(crownValue - combination[currentStep]) <= tolerance * boost {
            hapticProvider.play(.success)
            currentStep += 1
            if currentStep == combination.count {
                gameState = .success
            }
        } else {
            hapticProvider.play(.failure)
            detectionLevel += session.ownedUpgrades.contains("Відмички") ? 0.15 : 0.4
            currentStep = 0
            if detectionLevel >= 1.0 { gameState = .caught }
        }
    }

    private func handlePatrolLogic() {
        guard let district = activeDistrict, district.hasPatrol, !empActive else { return }
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

    private func failMission() {
        gameState = .caught
        hapticProvider.play(.failure)
    }

    func useSmokeBomb() {
        guard session.consume("Дим. шашка") else { return }
        withAnimation { detectionLevel = 0.0 }
        hapticProvider.play(.success)
    }
}
