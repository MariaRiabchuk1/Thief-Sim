import Foundation

/// An upgrade or gadget available in the shop.
struct Upgrade: Identifiable, Equatable {
    let id: UpgradeID
    let name: String
    let icon: String
    let price: Int
    let description: String
    let helpText: String
    let isConsumable: Bool
}
