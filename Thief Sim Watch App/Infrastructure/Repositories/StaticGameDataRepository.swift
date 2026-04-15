import Foundation
import SwiftUI

/// Static implementation of the game data repository.
class StaticGameDataRepository: GameDataRepository {
    func getDistricts() -> [District] {
        [
            District(name: "Примістя", reward: 200, codeLength: 1, safeTolerance: 3.5, hackSpeed: 2.0, hasPatrol: false, timeLimit: nil, unlockPrice: 0),
            District(name: "Центр", reward: 800, codeLength: 2, safeTolerance: 2.0, hackSpeed: 4.0, hasPatrol: true, timeLimit: 45, unlockPrice: 2000),
            District(name: "Острів", reward: 3000, codeLength: 3, safeTolerance: 1.2, hackSpeed: 6.0, hasPatrol: true, timeLimit: 30, unlockPrice: 10000)
        ]
    }
    
    func getShopItems() -> [Upgrade] {
        [
            Upgrade(name: "Стетоскоп", icon: "ear", price: 1000, description: "Сенсор x1.5", helpText: "Збільшує зону вібрації та сяйва.", isConsumable: false),
            Upgrade(name: "Відмички", icon: "key.fill", price: 2500, description: "Шанс помилки", helpText: "Зменшує приріст шуму при помилці.", isConsumable: false),
            Upgrade(name: "Дим. шашка", icon: "wind", price: 300, description: "-100% шуму", helpText: "Скидає рівень підозри.", isConsumable: true),
            Upgrade(name: "ЕМІ", icon: "bolt.fill", price: 800, description: "Блок патруля", helpText: "Вимикає сигналізацію.", isConsumable: true)
        ]
    }
    
    func getSkins() -> [Skin] {
        [
            Skin(name: "Класика", color: Color(red: 0.2, green: 0.4, blue: 0.8), price: 0, description: "Стандарт"),
            Skin(name: "Ніндзя", color: Color(white: 0.1), price: 1500, description: "Тінь"),
            Skin(name: "Неон", color: .green, price: 5000, description: "Кібер-злодій")
        ]
    }
    
    func getAccessories() -> [Accessory] {
        [
            Accessory(name: "Кепка", icon: "🧢", price: 300, offset: CGPoint(x: 0, y: -8)),
            Accessory(name: "Циліндр", icon: "🎩", price: 1500, offset: CGPoint(x: 0, y: -10)),
            Accessory(name: "Рюкзак", icon: "🎒", price: 800, offset: CGPoint(x: -6, y: 4)),
            Accessory(name: "Окуляри", icon: "🕶️", price: 2000, offset: CGPoint(x: 0, y: -4))
        ]
    }
}
