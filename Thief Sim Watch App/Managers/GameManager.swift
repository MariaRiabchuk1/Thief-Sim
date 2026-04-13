import SwiftUI
import WatchKit
import Combine

class GameManager: ObservableObject {
    // static constants (Data)
    static let districtsData = [
        District(name: "Примістя", reward: 200, codeLength: 1, safeTolerance: 3.0, hackSpeed: 2.0, hasPatrol: false, timeLimit: nil),
        District(name: "Центр", reward: 800, codeLength: 2, safeTolerance: 1.5, hackSpeed: 4.0, hasPatrol: true, timeLimit: 45),
        District(name: "Острів", reward: 3000, codeLength: 3, safeTolerance: 1.0, hackSpeed: 6.0, hasPatrol: true, timeLimit: 30)
    ]
    
    static let shopItemsData = [
        Upgrade(name: "Стетоскоп", icon: "ear", price: 1000, description: "Сенсор x1.5", helpText: "Збільшує зону вібрації та сяйва. Код відчувається набагато легше.", isConsumable: false),
        Upgrade(name: "Відмички", icon: "key.fill", price: 2500, description: "Шанс помилки", helpText: "Зменшує приріст шуму при помилковому зламі на 50%.", isConsumable: false),
        Upgrade(name: "Дим. шашка", icon: "wind", price: 300, description: "-100% шуму", helpText: "Використовується під час злому сейфа. Миттєво скидає рівень підозри до нуля.", isConsumable: true),
        Upgrade(name: "ЕМІ", icon: "bolt.fill", price: 800, description: "Блок патруля", helpText: "Вимикає сигналізацію та патрулі на весь поточний рівень. Використовуй під час хакінгу.", isConsumable: true)
    ]

    // States
    @Published var gameState: GameState = .map
    @Published var totalMoney = 0
    @Published var selectedDistrictIndex = 0
    @Published var ownedUpgrades: Set<String> = []
    @Published var consumables: [String: Int] = ["Дим. шашка": 0, "ЕМІ": 0]
    @Published var totalEarnings = 0
    
    // Level State
    @Published var detectionLevel: Double = 0.0
    @Published var empActive = false
    @Published var timeRemaining: Int = 0
    @Published var isTreasureLevel = false
    @Published var isLockStuck = false
    @Published var stuckProgress = 0
    @Published var infoAlert: Upgrade? = nil
    
    // Vent State
    @Published var ventPosition: CGFloat = 70.0
    @Published var ventDistance: Double = 0.0
    @Published var obstacles: [Obstacle] = []
    
    // Hacking State
    @Published var hackPosition: CGFloat = 0.0
    @Published var hackDirection: CGFloat = 1.0
    
    // Safe State
    @Published var combination: [Double] = []
    @Published var currentStep = 0
    @Published var crownValue: Double = 50.0
    @Published var lastFeedbackValue: Double = 50.0
    @Published var resonanceAlpha: Double = 0.0
    
    // Patrol State
    @Published var isPatrolActive = false
    @Published var isPatrolWarning = false
    @Published var patrolTick = 0
    
    var currentDistrict: District {
        GameManager.districtsData[selectedDistrictIndex]
    }
    
    var playerRank: String {
        if totalEarnings < 1000 { return "Новачок" }
        if totalEarnings < 5000 { return "Зломщик" }
        if totalEarnings < 15000 { return "Майстер" }
        return "Привид"
    }

    // Timers handling
    func startMission() {
        let district = currentDistrict
        detectionLevel = 0.0; empActive = false; isPatrolActive = false; isPatrolWarning = false
        patrolTick = 0; hackPosition = 0; currentStep = 0; crownValue = 50.0; lastFeedbackValue = 50.0
        timeRemaining = district.timeLimit ?? 0; isTreasureLevel = Int.random(in: 0...100) < 15
        ventDistance = 0; ventPosition = 70; obstacles = []
        combination = (0..<district.codeLength).map { _ in Double.random(in: 10...90).rounded() }
        gameState = .ventCrawl
    }
    
    func handleFastTick() {
        if gameState == .ventCrawl {
            handleVentTick()
        } else if gameState == .hacking {
            handleHackingTick()
        }
    }
    
    private func handleVentTick() {
        ventDistance += 0.5
        for i in 0..<obstacles.count {
            obstacles[i].y += 3
            if abs(obstacles[i].y - 120) < 10 && abs(obstacles[i].x - ventPosition) < 25 {
                gameState = .caught; WKInterfaceDevice.current().play(.failure)
            }
        }
        obstacles.removeAll { $0.y > 160 }
        if Int.random(in: 0...100) < 8 { obstacles.append(Obstacle(x: CGFloat.random(in: 30...110), y: -10)) }
        if ventDistance >= 100 { gameState = .hacking; WKInterfaceDevice.current().play(.success) }
    }
    
    private func handleHackingTick() {
        hackPosition += currentDistrict.hackSpeed * hackDirection
        if hackPosition > 55 || hackPosition < -55 { hackDirection *= -1 }
    }
    
    func handleGlobalTick() {
        guard gameState == .safeCracking else { return }
        if timeRemaining > 0 { timeRemaining -= 1; if timeRemaining == 0 { gameState = .caught } }
        if detectionLevel > 0.2 && patrolTick % max(2, Int(10 - detectionLevel * 8)) == 0 { WKInterfaceDevice.current().play(.click) }
        if !isLockStuck && Int.random(in: 0...100) < 3 { isLockStuck = true; stuckProgress = 0; WKInterfaceDevice.current().play(.failure) }
        handlePatrolTick()
    }
    
    func handleSafeInput(_ value: Double) {
        let target = combination[currentStep]
        let distance = abs(value - target)
        let boost = ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0
        withAnimation(.linear(duration: 0.1)) { resonanceAlpha = max(0, 1.0 - (distance / (15.0 * boost))) }
        if floor(value) != floor(lastFeedbackValue) {
            if isPatrolActive { detectionLevel += 0.35; WKInterfaceDevice.current().play(.failure) }
            else {
                if distance <= currentDistrict.safeTolerance * boost { WKInterfaceDevice.current().play(.notification) }
                else { WKInterfaceDevice.current().play(.click) }
                if abs(value - lastFeedbackValue) > 2.5 { detectionLevel += 0.02 }
            }
            lastFeedbackValue = value
        }
        if detectionLevel >= 1.0 { gameState = .caught }
    }
    
    func tryCrackSafe() {
        if isPatrolActive || isLockStuck { return }
        let boost = ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0
        if abs(crownValue - combination[currentStep]) <= currentDistrict.safeTolerance * boost {
            WKInterfaceDevice.current().play(.success); currentStep += 1
            if currentStep == combination.count { gameState = .success }
        } else {
            WKInterfaceDevice.current().play(.failure)
            detectionLevel += ownedUpgrades.contains("Відмички") ? 0.15 : 0.35
            currentStep = 0; if detectionLevel >= 1.0 { gameState = .caught }
        }
    }
    
    private func handlePatrolTick() {
        guard gameState == .safeCracking && currentDistrict.hasPatrol && !empActive else { return }
        patrolTick += 1
        if !isPatrolActive && !isPatrolWarning {
            if Int.random(in: 0...100) > 85 { isPatrolWarning = true; WKInterfaceDevice.current().play(.directionUp); patrolTick = 0 }
        } else if isPatrolWarning && patrolTick >= 2 { isPatrolWarning = false; isPatrolActive = true; WKInterfaceDevice.current().play(.stop); patrolTick = 0 }
        else if isPatrolActive && patrolTick >= 3 { isPatrolActive = false; WKInterfaceDevice.current().play(.directionDown) }
    }
    
    func buyItem(_ item: Upgrade) {
        if totalMoney >= item.price {
            totalMoney -= item.price
            if item.isConsumable { consumables[item.name, default: 0] += 1 }
            else { ownedUpgrades.insert(item.name) }
            WKInterfaceDevice.current().play(.success)
        }
    }
}
