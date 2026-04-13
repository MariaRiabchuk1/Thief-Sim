import SwiftUI

struct ShopScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { manager.gameState = .map }) {
                    Text("НАЗАД").font(.system(size: 9, weight: .medium)).foregroundColor(.blue)
                }.buttonStyle(.plain)
            }.padding(.horizontal, 12).padding(.top, 5).padding(.bottom, 2)
            
            List(GameManager.shopItemsData) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name).font(.system(size: 11, weight: .bold))
                        Text("$\(item.price)").font(.system(size: 9)).foregroundColor(.yellow)
                    }
                    Spacer()
                    Button(action: { manager.infoAlert = item }) { Image(systemName: "info.circle").foregroundColor(.blue) }.buttonStyle(.plain).padding(.trailing, 8)
                    Button(action: { manager.buyItem(item) }) {
                        if !item.isConsumable && manager.ownedUpgrades.contains(item.name) {
                            Image(systemName: "checkmark").foregroundColor(.green)
                        } else {
                            Text(item.isConsumable ? "+\(manager.consumables[item.name, default: 0])" : "КУПИТИ").font(.system(size: 8, weight: .bold)).padding(4).background(manager.totalMoney >= item.price ? Color.blue : Color.gray).cornerRadius(4)
                        }
                    }
                    .disabled(!item.isConsumable && manager.ownedUpgrades.contains(item.name) || manager.totalMoney < item.price)
                }
            }
        }
    }
}
