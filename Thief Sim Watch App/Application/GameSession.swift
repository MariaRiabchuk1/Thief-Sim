import Foundation
import Combine
import WatchKit

/// Cross-cutting player progression and catalog data.
///
/// Owns everything that persists across screens and survives a mission: money,
/// unlocks, purchased upgrades, customization, and the static catalogs the UI
/// reads from. Mission-scoped or minigame-scoped state does NOT belong here.
final class GameSession: ObservableObject {
    // Economy
    @Published var totalMoney: Int = 0
    @Published var totalEarnings: Int = 0

    // Progression
    @Published var unlockedDistricts: Set<String> = []
    @Published var ownedUpgrades: Set<String> = []
    @Published var ownedSkins: Set<String> = ["Класика"]
    @Published var ownedAccessories: Set<String> = []
    @Published var consumables: [String: Int] = ["Дим. шашка": 0, "ЕМІ": 0]
    @Published var districtProgress: [String: Int] = [:]

    // Active customization
    @Published var currentSkinName: String = "Класика"
    @Published var currentAccessoryName: String? = nil

    // Catalogs
    let districts: [District]
    let shopItems: [Upgrade]
    let skins: [Skin]
    let accessories: [Accessory]

    // Dependencies
    private let economyService: EconomyService
    private let hapticProvider: HapticProvider

    init(
        dataRepository: GameDataRepository = StaticGameDataRepository(),
        economyService: EconomyService = GameEconomyService(),
        hapticProvider: HapticProvider = WatchHapticProvider()
    ) {
        self.economyService = economyService
        self.hapticProvider = hapticProvider
        self.districts = dataRepository.getDistricts()
        self.shopItems = dataRepository.getShopItems()
        self.skins = dataRepository.getSkins()
        self.accessories = dataRepository.getAccessories()

        if let first = districts.first {
            self.unlockedDistricts.insert(first.name)
        }
    }

    // Lookups
    var currentSkin: Skin { skins.first { $0.name == currentSkinName } ?? skins[0] }
    var currentAccessory: Accessory? { accessories.first { $0.name == currentAccessoryName } }
    var playerRank: String { economyService.getPlayerRank(totalEarnings: totalEarnings) }
    func level(of district: District) -> Int { districtProgress[district.name, default: 0] }

    // Economy
    func unlockDistrict(_ district: District) {
        guard economyService.canUnlockDistrict(totalMoney: totalMoney, district: district) else { return }
        totalMoney -= district.unlockPrice
        unlockedDistricts.insert(district.name)
        hapticProvider.play(.success)
    }

    func buySkin(_ skin: Skin) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: skin.price) else { return }
        totalMoney -= skin.price
        ownedSkins.insert(skin.name)
        currentSkinName = skin.name
        hapticProvider.play(.success)
    }

    func buyAccessory(_ accessory: Accessory) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: accessory.price) else { return }
        totalMoney -= accessory.price
        ownedAccessories.insert(accessory.name)
        currentAccessoryName = accessory.name
        hapticProvider.play(.success)
    }

    func buyUpgrade(_ item: Upgrade) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: item.price) else { return }
        totalMoney -= item.price
        if item.isConsumable {
            consumables[item.name, default: 0] += 1
        } else {
            ownedUpgrades.insert(item.name)
        }
        hapticProvider.play(.success)
    }

    func bribePrice(for district: District) -> Int {
        economyService.calculateBribePrice(reward: district.reward)
    }

    func payBribe(for district: District) -> Bool {
        let price = bribePrice(for: district)
        guard totalMoney >= price else { return false }
        totalMoney -= price
        hapticProvider.play(.success)
        return true
    }

    func applyUpkeep() {
        let upkeep = economyService.getUpkeepCost(unlockedDistrictsCount: unlockedDistricts.count)
        totalMoney = max(0, totalMoney - upkeep)
    }

    func addReward(_ amount: Int) {
        totalMoney += amount
        totalEarnings += amount
    }

    func halveMoney() {
        totalMoney /= 2
    }

    func advanceProgress(in district: District) {
        districtProgress[district.name, default: 0] += 1
    }

    @discardableResult
    func consume(_ itemName: String) -> Bool {
        guard (consumables[itemName] ?? 0) > 0 else { return false }
        consumables[itemName]! -= 1
        return true
    }
}
