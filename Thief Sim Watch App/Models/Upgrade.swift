import Foundation

struct Upgrade: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let price: Int
    let description: String
    let helpText: String
    let isConsumable: Bool
}

extension Upgrade {
    static var placeholder: Upgrade {
        Upgrade(name: "", icon: "", price: 0, description: "", helpText: "", isConsumable: false)
    }
}
