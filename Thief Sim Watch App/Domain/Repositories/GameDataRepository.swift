import Foundation

/// Data repository for game-related static data.
protocol GameDataRepository {
    func getDistricts() -> [District]
    func getShopItems() -> [Upgrade]
    func getSkins() -> [Skin]
    func getAccessories() -> [Accessory]
}
