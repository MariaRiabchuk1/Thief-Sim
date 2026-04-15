import Foundation
import SwiftUI

enum GameState {
    case map, shop, ventCrawl, hacking, safeCracking, caught, success
}

struct District: Identifiable {
    let id = UUID()
    let name: String
    let reward: Int
    let codeLength: Int
    let safeTolerance: Double
    let hackSpeed: Double
    let hasPatrol: Bool
    let timeLimit: Int?
}

struct Upgrade: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let price: Int
    let description: String
    let helpText: String
    let isConsumable: Bool
}

struct Skin: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let price: Int
    let description: String
}

struct Accessory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let price: Int
    let offset: CGPoint
}

enum ObstacleType {
    case wall, enemy, turret
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var width: Double
    var type: ObstacleType
    var speedX: Double = 0
    var lastShootTime: Double = 0
}

struct Bullet: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
}

extension Upgrade {
    static var placeholder: Upgrade {
        Upgrade(name: "", icon: "", price: 0, description: "", helpText: "", isConsumable: false)
    }
}
