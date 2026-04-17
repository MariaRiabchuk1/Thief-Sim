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
    @Published var unlockedDistricts: Set<DistrictID> = []
    @Published var ownedUpgrades: Set<UpgradeID> = []
    @Published var ownedSkins: Set<SkinID> = [.classic]
    @Published var ownedAccessories: Set<AccessoryID> = []
    @Published var consumables: [UpgradeID: Int] = [.smokeBomb: 0, .emp: 0]
    @Published var districtProgress: [DistrictID: Int] = [:]
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
    private let progressRepository: ProgressRepository

    init(
        dataRepository: GameDataRepository = StaticGameDataRepository(),
        economyService: EconomyService = GameEconomyService(),
        hapticProvider: HapticProvider = WatchHapticProvider(),
        progressRepository: ProgressRepository = UserDefaultsProgressRepository()
    ) {
        self.economyService = economyService
        self.hapticProvider = hapticProvider
        self.progressRepository = progressRepository
        
        self.districts = dataRepository.getDistricts()
        self.shopItems = dataRepository.getShopItems()
        self.skins = dataRepository.getSkins()
        self.accessories = dataRepository.getAccessories()

        loadProgress()

        if unlockedDistricts.isEmpty, let first = districts.first {
            unlockedDistricts.insert(first.id)
            lastSelectedDistrictId = first.id
        }
        
        syncToComplication()
    }

    // Persist
    private func saveProgress() {
        let snapshot = PlayerProgress(
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
        progressRepository.save(snapshot)
    }

    private func loadProgress() {
        guard let snapshot = progressRepository.load() else { return }
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
    func level(of district: District) -> Int { districtProgress[district.id, default: 0] }

    // Sync
    private func syncToComplication() {
        ComplicationDataService.shared.save(balance: totalMoney, districtId: lastSelectedDistrictId)
    }

    // Economy
    func unlockDistrict(_ district: District) {
        guard economyService.canUnlockDistrict(totalMoney: totalMoney, district: district) else { return }
        totalMoney -= district.unlockPrice
        unlockedDistricts.insert(district.id)
        hapticProvider.play(.notification)
        syncToComplication()
        saveProgress()
    }

    func buySkin(_ skin: Skin) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: skin.price) else { return }
        totalMoney -= skin.price
        ownedSkins.insert(skin.id)
        currentSkinName = skin.name
        hapticProvider.play(.success)
        syncToComplication()
        saveProgress()
    }

    func buyAccessory(_ accessory: Accessory) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: accessory.price) else { return }
        totalMoney -= accessory.price
        ownedAccessories.insert(accessory.id)
        currentAccessoryName = accessory.name
        hapticProvider.play(.success)
        syncToComplication()
        saveProgress()
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
        saveProgress()
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
        saveProgress()
        return true
    }

    func applyUpkeep() {
        let upkeep = economyService.getUpkeepCost(unlockedDistrictsCount: unlockedDistricts.count)
        totalMoney = max(0, totalMoney - upkeep)
        syncToComplication()
        saveProgress()
    }

    func addReward(_ amount: Int) {
        totalMoney += amount
        totalEarnings += amount
        syncToComplication()
        saveProgress()
    }

    func halveMoney() {
        totalMoney /= 2
        syncToComplication()
        saveProgress()
    }

    func advanceProgress(in district: District) {
        districtProgress[district.id, default: 0] += 1
        saveProgress()
    }

    @discardableResult
    func consume(_ id: UpgradeID) -> Bool {
        guard (consumables[id] ?? 0) > 0 else { return false }
        consumables[id]! -= 1
        syncToComplication()
        saveProgress()
        return true
    }
    
    func selectDistrict(_ id: DistrictID) {
        lastSelectedDistrictId = id
        syncToComplication()
    }

    func markCoachMarkSeen(_ id: String) {
        seenCoachMarks.insert(id)
        saveProgress()
    }
}
