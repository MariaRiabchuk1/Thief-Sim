import Foundation

/// An upgrade or gadget available in the shop.
struct Upgrade: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let price: Int
    let description: String
    let helpText: String
    let isConsumable: Bool
    
    static var placeholder: Upgrade {
        Upgrade(name: "", icon: "", price: 0, description: "", helpText: "", isConsumable: false)
    }
}
