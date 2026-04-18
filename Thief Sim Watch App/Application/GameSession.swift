import Foundation
import Combine
import WatchKit

/// Cross-cutting player progression and catalog data.
final class GameSession: ObservableObject {
    // Economy
    @Published var totalMoney: Int = 0
    @Published var totalEarnings: Int = 0
    @Published var activeDeduction: MoneyDeduction?

    struct MoneyDeduction: Equatable {
        let amount: Int
        let reason: String
    }

    // Progression
    @Published var unlockedDistricts: Set<DistrictID> = []
    @Published var ownedUpgrades: Set<UpgradeID> = []
    @Published var ownedSkins: Set<SkinID> = [.classic]
    @Published var ownedAccessories: Set<AccessoryID> = []
    @Published var consumables: [UpgradeID: Int] = [.smokeBomb: 0, .emp: 0]
    @Published var districtProgress: [DistrictID: Int] = [:]
    @Published var lastSelectedDistrictId: DistrictID = .outskirts

    // Active customization
    @Published var currentSkinName: String = "Класика" {
        didSet { saveProgress() }
    }
    @Published var currentAccessoryName: String? = nil {
        didSet { saveProgress() }
    }
    @Published var seenCoachMarks: Set<String> = []

    // Catalogs
    let districts: [District]
    let shopItems: [Upgrade]
    let skins: [Skin]
    let accessories: [Accessory]

    // Dependencies
    let economyService: EconomyService
    private let hapticProvider: HapticProvider
    private let progressRepository: ProgressRepository
    
    private var isInitialized = false

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

        checkBuildAndLoad()

        if unlockedDistricts.isEmpty, let first = districts.first {
            unlockedDistricts.insert(first.id)
            lastSelectedDistrictId = first.id
        }
        
        isInitialized = true
        syncToComplication()
    }

    /// Detects if this is a new build/install and resets progress if so.
    private func checkBuildAndLoad() {
        let buildKey = "last_build_date"
        let currentBuildDate = getBuildDate()
        let storedBuildDate = UserDefaults.standard.string(forKey: buildKey)
        
        if currentBuildDate != storedBuildDate {
            print("GameSession: New build detected. Resetting progress.")
            UserDefaults.standard.set(currentBuildDate, forKey: buildKey)
            saveProgress() 
        } else {
            loadProgress()
        }
    }
    
    private func getBuildDate() -> String {
        if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
           let modificationDate = infoAttr[.modificationDate] as? Date {
            return "\(modificationDate.timeIntervalSince1970)"
        }
        return "unknown"
    }

    // Persist
    private func saveProgress() {
        guard isInitialized else { return }
        
        let snapshot = PlayerProgress(
            totalMoney: totalMoney,
            totalEarnings: totalEarnings,
            unlockedDistricts: unlockedDistricts.map { $0.rawValue },
            ownedUpgrades: ownedUpgrades.map { $0.rawValue },
            ownedSkins: ownedSkins.map { $0.rawValue },
            ownedAccessories: ownedAccessories.map { $0.rawValue },
            consumables: Dictionary(uniqueKeysWithValues: consumables.map { ($0.key.rawValue, $0.value) }),
            districtProgress: Dictionary(uniqueKeysWithValues: districtProgress.map { ($0.key.rawValue, $0.value) }),
            currentSkinName: currentSkinName,
            currentAccessoryName: currentAccessoryName,
            seenCoachMarks: Array(seenCoachMarks)
        )
        progressRepository.save(snapshot)
    }

    private func loadProgress() {
        guard let snapshot = progressRepository.load() else { return }
        
        self.totalMoney = snapshot.totalMoney
        self.totalEarnings = snapshot.totalEarnings
        self.unlockedDistricts = Set(snapshot.unlockedDistricts.compactMap { DistrictID(rawValue: $0) })
        self.ownedUpgrades = Set(snapshot.ownedUpgrades.compactMap { UpgradeID(rawValue: $0) })
        self.ownedSkins = Set(snapshot.ownedSkins.compactMap { SkinID(rawValue: $0) })
        self.ownedAccessories = Set(snapshot.ownedAccessories.compactMap { AccessoryID(rawValue: $0) })
        
        var mappedConsumables: [UpgradeID: Int] = [:]
        for (key, value) in snapshot.consumables {
            if let id = UpgradeID(rawValue: key) { mappedConsumables[id] = value }
        }
        self.consumables = mappedConsumables
        
        var mappedProgress: [DistrictID: Int] = [:]
        for (key, value) in snapshot.districtProgress {
            if let id = DistrictID(rawValue: key) { mappedProgress[id] = value }
        }
        self.districtProgress = mappedProgress
        
        self.currentSkinName = snapshot.currentSkinName
        self.currentAccessoryName = snapshot.currentAccessoryName
        self.seenCoachMarks = Set(snapshot.seenCoachMarks)
        
        self.ownedSkins.insert(.classic)
    }

    // Lookups
    var currentSkin: Skin { skins.first { $0.name == currentSkinName } ?? skins[0] }
    var currentAccessory: Accessory? { accessories.first { $0.name == currentAccessoryName } }
    var playerRank: String { economyService.getPlayerRank(totalEarnings: totalEarnings) }
    func level(of district: District) -> Int { districtProgress[district.id, default: 0] }

    private func syncToComplication() {
        ComplicationDataService.shared.save(balance: totalMoney, districtId: lastSelectedDistrictId)
    }
    
    private func triggerDeductionNotice(amount: Int, reason: String) {
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.activeDeduction = MoneyDeduction(amount: amount, reason: reason)
            // Auto-clear after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.activeDeduction?.amount == amount {
                    self?.activeDeduction = nil
                }
            }
        }
    }

    // Economy
    func unlockDistrict(_ district: District) {
        guard economyService.canUnlockDistrict(totalMoney: totalMoney, district: district) else { return }
        totalMoney -= district.unlockPrice
        unlockedDistricts.insert(district.id)
        hapticProvider.play(.notification)
        syncToComplication()
        saveProgress()
        triggerDeductionNotice(amount: district.unlockPrice, reason: "Розблокування")
    }

    func buySkin(_ skin: Skin) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: skin.price) else { return }
        totalMoney -= skin.price
        ownedSkins.insert(skin.id)
        currentSkinName = skin.name
        hapticProvider.play(.success)
        syncToComplication()
        saveProgress()
        triggerDeductionNotice(amount: skin.price, reason: skin.name)
    }

    func buyAccessory(_ accessory: Accessory) {
        guard economyService.canBuyItem(totalMoney: totalMoney, price: accessory.price) else { return }
        totalMoney -= accessory.price
        ownedAccessories.insert(accessory.id)
        currentAccessoryName = accessory.name
        hapticProvider.play(.success)
        syncToComplication()
        saveProgress()
        triggerDeductionNotice(amount: accessory.price, reason: accessory.name)
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
        triggerDeductionNotice(amount: item.price, reason: item.name)
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
        triggerDeductionNotice(amount: price, reason: "Підкуп")
        return true
    }

    func applyUpkeep() {
        let upkeep = economyService.getUpkeepCost(unlockedDistrictsCount: unlockedDistricts.count)
        guard upkeep > 0 else { return }
        totalMoney = max(0, totalMoney - upkeep)
        syncToComplication()
        saveProgress()
        triggerDeductionNotice(amount: upkeep, reason: "Оренда")
    }

    func addReward(_ amount: Int) {
        totalMoney += amount
        totalEarnings += amount
        syncToComplication()
        saveProgress()
    }

    func subtractBailFee(_ amount: Int) {
        totalMoney = max(0, totalMoney - amount)
        syncToComplication()
        saveProgress()
        triggerDeductionNotice(amount: amount, reason: "Застава")
    }

    func removeRandomConsumable() {
        let available = consumables.filter { $0.value > 0 }.map { $0.key }
        guard let randomID = available.randomElement() else { return }
        consumables[randomID, default: 0] -= 1
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
        saveProgress()
    }

    func markCoachMarkSeen(_ id: String) {
        seenCoachMarks.insert(id)
        saveProgress()
    }
}
