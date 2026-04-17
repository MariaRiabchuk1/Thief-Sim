import Foundation
import Combine
import WatchKit

/// Cross-cutting player progression and catalog data.
final class GameSession: ObservableObject {
    // Economy
    @Published var totalMoney: Int = 0
    @Published var totalEarnings: Int = 0

    // Progression
    @Published var unlockedDistricts: Set<String> = []
    @Published var ownedUpgrades: Set<UpgradeID> = []
    @Published var ownedSkins: Set<String> = ["Класика"]
    @Published var ownedAccessories: Set<String> = []
    @Published var consumables: [UpgradeID: Int] = [.smokeBomb: 0, .emp: 0]
    @Published var districtProgress: [String: Int] = [:]
    @Published var lastSelectedDistrictId: DistrictID = .outskirts

    // Active customization
    @Published var currentSkinName: String = "Класика"
    @Published var currentAccessoryName: String? = nil
    @Published var seenCoachMarks: Set<String> = []

    // Catalogs
    let districts: [District]
    let shopItems: [Upgrade]
    let skins: [Skin]
    let accessories: [Accessory]

    // Dependencies
    private let economyService: EconomyService
    private let hapticProvider: HapticProvider
    private let persistence: SessionPersistenceService

    init(
        dataRepository: GameDataRepository = StaticGameDataRepository(),
        economyService: EconomyService = GameEconomyService(),
        hapticProvider: HapticProvider = WatchHapticProvider(),
        persistence: SessionPersistenceService = .shared
    ) {
        self.economyService = economyService
        self.hapticProvider = hapticProvider
        self.persistence = persistence
        
        self.districts = dataRepository.getDistricts()
        self.shopItems = dataRepository.getShopItems()
        self.skins = dataRepository.getSkins()
        self.accessories = dataRepository.getAccessories()

        loadSession()

        if unlockedDistricts.isEmpty, let first = districts.first {
            unlockedDistricts.insert(first.name)
            lastSelectedDistrictId = first.id
        }
        
        syncToComplication()
    }

    // Persist
    private func saveSession() {
        let snapshot = GameSessionSnapshot(
            totalMoney: totalMoney,
            totalEarnings: totalEarnings,
            unlockedDistricts: unlockedDistricts,
            ownedUpgrades: ownedUpgrades,
            ownedSkins: ownedSkins,
            ownedAccessories: ownedAccessories,
            consumables: consumables,
            districtProgress: districtProgress,
            currentSkinName: currentSkinName,
            currentAccessoryName: currentAccessoryName,
            seenCoachMarks: seenCoachMarks
        )
        persistence.save(snapshot)
    }

    private func loadSession() {
        guard let snapshot = persistence.load() else { return }
        self.totalMoney = snapshot.totalMoney
        self.totalEarnings = snapshot.totalEarnings
        self.unlockedDistricts = snapshot.unlockedDistricts
        self.ownedUpgrades = snapshot.ownedUpgrades
        self.ownedSkins = snapshot.ownedSkins
        self.ownedAccessories = snapshot.ownedAccessories
        self.consumables = snapshot.consumables
        self.districtProgress = snapshot.districtProgress
        self.currentSkinName = snapshot.currentSkinName
        self.currentAccessoryName = snapshot.currentAccessoryName
        self.seenCoachMarks = snapshot.seenCoachMarks
    }

    // Lookups
    var currentSkin: Skin { skins.first { $0.name == currentSkinName } ?? skins[0] }
    var currentAccessory: Accessory? { accessories.first { $0.name == currentAccessoryName } }
    var playerRank: String { economyService.getPlayerRank(totalEarnings: totalEarnings) }
    func level(of district: District) -> Int { districtProgress[district.name, default: 0] }

    // Sync
    private func syncToComplication() {
        ComplicationDataService.shared.save(balance: totalMoney, districtId: lastSelectedDistrictId)
    }

    // Economy
    func unlockDistrict(_ district: District) {
        guard economyService.canUnlockDistrict(totalMoney: totalMoney, district: district) else { return }
        totalMoney -= district.unlockPrice
        unlockedDistricts.insert(district.name)
        hapticProvider.play(.notification)
        syncToComplication()
        saveSession()
    }

    func buySkin(_ skin: Skin) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: skin.price) else { return }
        totalMoney -= skin.price
        ownedSkins.insert(skin.name)
        currentSkinName = skin.name
        hapticProvider.play(.success)
        syncToComplication()
        saveSession()
    }

    func buyAccessory(_ accessory: Accessory) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: accessory.price) else { return }
        totalMoney -= accessory.price
        ownedAccessories.insert(accessory.name)
        currentAccessoryName = accessory.name
        hapticProvider.play(.success)
        syncToComplication()
        saveSession()
    }

    func buyUpgrade(_ item: Upgrade) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: item.price) else { return }
        totalMoney -= item.price
        if item.isConsumable {
            consumables[item.id, default: 0] += 1
        } else {
            ownedUpgrades.insert(item.id)
        }
        hapticProvider.play(.success)
        syncToComplication()
        saveSession()
    }

    func bribePrice(for district: District) -> Int {
        economyService.calculateBribePrice(reward: district.reward)
    }

    func payBribe(for district: District) -> Bool {
        let price = bribePrice(for: district)
        guard totalMoney >= price else { return false }
        totalMoney -= price
        hapticProvider.play(.success)
        syncToComplication()
        saveSession()
        return true
    }

    func applyUpkeep() {
        let upkeep = economyService.getUpkeepCost(unlockedDistrictsCount: unlockedDistricts.count)
        totalMoney = max(0, totalMoney - upkeep)
        syncToComplication()
        saveSession()
    }

    func addReward(_ amount: Int) {
        totalMoney += amount
        totalEarnings += amount
        syncToComplication()
        saveSession()
    }

    func halveMoney() {
        totalMoney /= 2
        syncToComplication()
        saveSession()
    }

    func advanceProgress(in district: District) {
        districtProgress[district.name, default: 0] += 1
        saveSession()
    }

    @discardableResult
    func consume(_ id: UpgradeID) -> Bool {
        guard (consumables[id] ?? 0) > 0 else { return false }
        consumables[id]! -= 1
        syncToComplication()
        saveSession()
        return true
    }
    
    func selectDistrict(_ id: DistrictID) {
        lastSelectedDistrictId = id
        syncToComplication()
    }

    func markCoachMarkSeen(_ id: String) {
        seenCoachMarks.insert(id)
        saveSession()
    }
}
