import Foundation
import SwiftUI

/// Static implementation of the game data repository.
class StaticGameDataRepository: GameDataRepository {
    func getDistricts() -> [District] {
        [
            District(id: .outskirts, name: "Примістя", reward: 200, codeLength: 1, safeTolerance: 3.5, hackSpeed: 2.0, hasPatrol: false, timeLimit: nil, unlockPrice: 0),
            District(id: .center, name: "Центр", reward: 800, codeLength: 2, safeTolerance: 2.0, hackSpeed: 4.0, hasPatrol: true, timeLimit: 45, unlockPrice: 2000),
            District(id: .island, name: "Острів", reward: 3000, codeLength: 3, safeTolerance: 1.2, hackSpeed: 6.0, hasPatrol: true, timeLimit: 30, unlockPrice: 10000)
        ]
    }

    func getShopItems() -> [Upgrade] {
        [
            Upgrade(id: .stethoscope, name: "Стетоскоп", icon: "ear", price: 1000, description: "Сенсор x1.5", helpText: "Збільшує зону вібрації та сяйва.", isConsumable: false),
            Upgrade(id: .lockpicks, name: "Відмички", icon: "key.fill", price: 2500, description: "Шанс помилки", helpText: "Зменшує приріст шуму при помилці.", isConsumable: false),
            Upgrade(id: .smokeBomb, name: "Дим. шашка", icon: "wind", price: 300, description: "-100% шуму", helpText: "Скидає рівень підозри.", isConsumable: true),
            Upgrade(id: .emp, name: "ЕМІ", icon: "bolt.fill", price: 800, description: "Блок патруля", helpText: "Вимикає сигналізацію.", isConsumable: true)
        ]
    }

    func getSkins() -> [Skin] {
        [
            Skin(id: .classic, name: "Класика", color: Color(red: 0.2, green: 0.4, blue: 0.8), price: 0, description: "Стандарт", modifier: .none, modifierDescription: "Базовий костюм"),
            Skin(id: .ninja, name: "Ніндзя", color: Color(white: 0.1), price: 1500, description: "Тінь", modifier: .silentSafeCracking, modifierDescription: "-15% шуму при зламі"),
            Skin(id: .neon, name: "Неон", color: .green, price: 5000, description: "Кібер-злодій", modifier: .preciseHacking, modifierDescription: "+20% вікно хакінгу")
        ]
    }

    func getAccessories() -> [Accessory] {
        [
            Accessory(id: .cap, name: "Кепка", icon: "🧢", price: 300, offset: CGPoint(x: 0, y: -8)),
            Accessory(id: .tophat, name: "Циліндр", icon: "🎩", price: 1500, offset: CGPoint(x: 0, y: -10)),
            Accessory(id: .backpack, name: "Рюкзак", icon: "🎒", price: 800, offset: CGPoint(x: -6, y: 4)),
            Accessory(id: .glasses, name: "Окуляри", icon: "🕶️", price: 2000, offset: CGPoint(x: 0, y: -4))
        ]
    }
}
