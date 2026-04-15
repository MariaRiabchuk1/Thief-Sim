import SwiftUI
import WatchKit
import Combine

class GameManager: ObservableObject {
    static let districtsData = [
        District(name: "Примістя", reward: 200, codeLength: 1, safeTolerance: 3.5, hackSpeed: 2.0, hasPatrol: false, timeLimit: nil),
        District(name: "Центр", reward: 800, codeLength: 2, safeTolerance: 2.0, hackSpeed: 4.0, hasPatrol: true, timeLimit: 45),
        District(name: "Острів", reward: 3000, codeLength: 3, safeTolerance: 1.2, hackSpeed: 6.0, hasPatrol: true, timeLimit: 30)
    ]
    
    static let shopItemsData = [
        Upgrade(name: "Стетоскоп", icon: "ear", price: 1000, description: "Сенсор x1.5", helpText: "Збільшує зону вібрації та сяйва.", isConsumable: false),
        Upgrade(name: "Відмички", icon: "key.fill", price: 2500, description: "Шанс помилки", helpText: "Зменшує приріст шуму при помилці.", isConsumable: false),
        Upgrade(name: "Дим. шашка", icon: "wind", price: 300, description: "-100% шуму", helpText: "Скидає рівень підозри.", isConsumable: true),
        Upgrade(name: "ЕМІ", icon: "bolt.fill", price: 800, description: "Блок патруля", helpText: "Вимикає сигналізацію.", isConsumable: true)
    ]
    
    static let accessoriesData = [
        Accessory(name: "Кепка", icon: "🧢", price: 300, offset: CGPoint(x: 0, y: -8)),
        Accessory(name: "Циліндр", icon: "🎩", price: 1500, offset: CGPoint(x: 0, y: -10)),
        Accessory(name: "Рюкзак", icon: "🎒", price: 800, offset: CGPoint(x: -6, y: 4)),
        Accessory(name: "Окуляри", icon: "🕶️", price: 2000, offset: CGPoint(x: 0, y: -4))
    ]

    static let skinsData = [
        Skin(name: "Класика", color: Color(red: 0.2, green: 0.4, blue: 0.8), price: 0, description: "Стандарт"),
        Skin(name: "Ніндзя", color: Color(white: 0.1), price: 1500, description: "Тінь"),
        Skin(name: "Неон", color: .green, price: 5000, description: "Кібер-злодій")
    ]

    @Published var gameState: GameState = .map
    @Published var totalMoney = 0
    @Published var selectedDistrictIndex = 0
    @Published var totalEarnings = 0
    @Published var ownedUpgrades: Set<String> = []
    @Published var consumables: [String: Int] = ["Дим. шашка": 0, "ЕМІ": 0]
    @Published var ownedSkins: Set<String> = ["Класика"]
    @Published var currentSkinName = "Класика"
    @Published var ownedAccessories: Set<String> = []
    @Published var currentAccessoryName: String? = nil
    @Published var districtProgress: [String: Int] = [:]
    
    @Published var detectionLevel: Double = 0.0
    @Published var timeRemaining: Int = 0
    @Published var empActive = false
    @Published var isTreasureLevel = false
    @Published var isLockStuck = false
    @Published var stuckProgress = 0
    @Published var infoAlert: Upgrade? = nil
    
    @Published var ventPosition: Double = 75.0
    @Published var ventDistance: Double = 0.0
    @Published var obstacles: [Obstacle] = []
    @Published var bullets: [Bullet] = []
    private var lastSpawnY: Double = -20.0
    
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
    
    var currentDistrict: District { GameManager.districtsData[selectedDistrictIndex] }
    var currentSkin: Skin { GameManager.skinsData.first { $0.name == currentSkinName } ?? GameManager.skinsData[0] }
    var currentAccessory: Accessory? { GameManager.accessoriesData.first { $0.name == currentAccessoryName } }
    var currentDistrictLevel: Int { districtProgress[currentDistrict.name, default: 0] }
    
    var playerRank: String {
        if totalEarnings < 1000 { return "Новачок" }
        if totalEarnings < 5000 { return "Зломщик" }
        if totalEarnings < 15000 { return "Майстер" }
        return "Привид"
    }

    func getScaledTolerance() -> Double {
        let base = currentDistrict.safeTolerance
        let reduction = Double(currentDistrictLevel) * 0.15
        let nextBase = selectedDistrictIndex < 2 ? GameManager.districtsData[selectedDistrictIndex+1].safeTolerance : 0.5
        return max(base - reduction, nextBase + 0.1)
    }

    func startMission() {
        let district = currentDistrict
        detectionLevel = 0.0; empActive = false; isPatrolActive = false; isPatrolWarning = false
        patrolTick = 0; currentStep = 0; crownValue = 50.0; lastFeedbackValue = 50.0
        timeRemaining = (district.timeLimit ?? 100) - (currentDistrictLevel * 2)
        isTreasureLevel = Int.random(in: 0...100) < 15
        ventDistance = 0; ventPosition = 75; obstacles = []; bullets = []; lastSpawnY = -20.0
        combination = (0..<district.codeLength).map { _ in Double.random(in: 10...90).rounded() }
        gameState = .ventCrawl
    }
    
    func handleFastTick() {
        if gameState == .ventCrawl {
            handleDungeonTick()
        } else if gameState == .hacking {
            hackPosition += (currentDistrict.hackSpeed + Double(currentDistrictLevel) * 0.5) * hackDirection
            if hackPosition > 55 || hackPosition < -55 { hackDirection *= -1 }
        }
    }
    
    private func handleDungeonTick() {
        ventDistance += 0.25
        for i in 0..<bullets.count { bullets[i].y += 4.0 }
        bullets.removeAll { $0.y > 160 }
        for i in 0..<obstacles.count {
            obstacles[i].y += 1.5
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
            if playerRect.intersects(obsRect) { gameState = .caught; WKInterfaceDevice.current().play(.failure) }
        }
        for bullet in bullets {
            let playerRect = CGRect(x: CGFloat(ventPosition - 6), y: 115, width: 12, height: 18)
            if playerRect.contains(CGPoint(x: CGFloat(bullet.x), y: CGFloat(bullet.y))) {
                gameState = .caught; WKInterfaceDevice.current().play(.failure)
            }
        }
        obstacles.removeAll { $0.y > 160 }
        if ventDistance - lastSpawnY > (35.0 - Double(currentDistrictLevel) * 2.0) {
            let rand = Int.random(in: 0...100)
            if rand < 30 {
                obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 15, type: .turret))
            } else if rand < 60 {
                obstacles.append(Obstacle(x: Double.random(in: 30...120), y: -10, width: 20, type: .enemy, speedX: 1.5 + Double(currentDistrictLevel) * 0.2))
            } else {
                let side = Bool.random()
                obstacles.append(Obstacle(x: side ? 35 : 115, y: -10, width: 70, type: .wall))
            }
            lastSpawnY = ventDistance
        }
        if ventDistance >= (100.0 + Double(currentDistrictLevel) * 10.0) { gameState = .hacking; WKInterfaceDevice.current().play(.success) }
    }
    
    func handleGlobalTick() {
        guard gameState == .safeCracking else { return }
        patrolTick += 1
        if timeRemaining > 0 { timeRemaining -= 1; if timeRemaining == 0 { gameState = .caught } }
        if detectionLevel > 0.2 && patrolTick % 2 == 0 { WKInterfaceDevice.current().play(.click) }
        handlePatrolTick()
    }
    
    func handleSafeInput(_ value: Double) {
        let tolerance = getScaledTolerance()
        let target = combination.isEmpty ? 0 : (currentStep < combination.count ? combination[currentStep] : 0)
        let distance = abs(value - target)
        let boost = ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0
        withAnimation(.linear(duration: 0.1)) { resonanceAlpha = max(0, 1.0 - (distance / (12.0 * boost))) }
        if floor(value) != floor(lastFeedbackValue) {
            if isPatrolActive { detectionLevel += 0.4; WKInterfaceDevice.current().play(.failure) }
            else {
                if distance <= tolerance * boost { WKInterfaceDevice.current().play(.notification) }
                else { WKInterfaceDevice.current().play(.click) }
            }
            lastFeedbackValue = value
        }
        if detectionLevel >= 1.0 { gameState = .caught }
    }
    
    func tryCrackSafe() {
        if isPatrolActive || isLockStuck || combination.isEmpty || currentStep >= combination.count { return }
        let boost = ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0
        if abs(crownValue - combination[currentStep]) <= getScaledTolerance() * boost {
            WKInterfaceDevice.current().play(.success); currentStep += 1
            if currentStep == combination.count { districtProgress[currentDistrict.name, default: 0] += 1; gameState = .success }
        } else {
            WKInterfaceDevice.current().play(.failure)
            detectionLevel += ownedUpgrades.contains("Відмички") ? 0.15 : 0.4
            currentStep = 0; if detectionLevel >= 1.0 { gameState = .caught }
        }
    }
    
    private func handlePatrolTick() {
        guard currentDistrict.hasPatrol && !empActive else { return }
        if !isPatrolActive && !isPatrolWarning {
            if Int.random(in: 0...100) > 80 { isPatrolWarning = true; WKInterfaceDevice.current().play(.directionUp) }
        } else if isPatrolWarning { isPatrolWarning = false; isPatrolActive = true; WKInterfaceDevice.current().play(.stop) }
        else if isPatrolActive { isPatrolActive = false; WKInterfaceDevice.current().play(.directionDown) }
    }
    
    func buySkin(_ skin: Skin) {
        if totalMoney >= skin.price {
            totalMoney -= skin.price; ownedSkins.insert(skin.name); currentSkinName = skin.name; WKInterfaceDevice.current().play(.success)
        }
    }
    
    func buyAccessory(_ acc: Accessory) {
        if totalMoney >= acc.price {
            totalMoney -= acc.price; ownedAccessories.insert(acc.name); currentAccessoryName = acc.name; WKInterfaceDevice.current().play(.success)
        }
    }
    
    func buyItem(_ item: Upgrade) {
        if totalMoney >= item.price {
            totalMoney -= item.price; if item.isConsumable { consumables[item.name, default: 0] += 1 }
            else { ownedUpgrades.insert(item.name) }; WKInterfaceDevice.current().play(.success)
        }
    }
}
