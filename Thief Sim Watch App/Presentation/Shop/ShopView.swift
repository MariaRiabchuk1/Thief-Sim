import SwiftUI

/// Shop screen for buying gadgets and customization.
struct ShopView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: -1) {
                    Text("$\(viewModel.totalMoney)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text(viewModel.playerRank)
                        .font(.system(size: 8))
                        .foregroundStyle(.blue)
                        .italic()
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
            }
            .padding(.leading, 22)
            .padding(.trailing, 44)
            .padding(.top, 6)

            HStack {
                Button(action: { viewModel.gameState = .map }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.3), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.top, 2)

            List {
                Section(header: Text("АКСЕСУАРИ").font(.system(size: 8))) {
                    ForEach(viewModel.accessories) { acc in
                        AccessoryRow(accessory: acc, viewModel: viewModel)
                    }
                }

                Section(header: Text("ГАДЖЕТИ").font(.system(size: 8))) {
                    ForEach(viewModel.shopItems) { item in
                        UpgradeRow(item: item, viewModel: viewModel)
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

private struct AccessoryRow: View {
    let accessory: Accessory
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        let isOwned = viewModel.ownedAccessories.contains(accessory.name)
        let isEquipped = viewModel.currentAccessoryName == accessory.name
        
        HStack {
            Text(accessory.icon).font(.system(size: 14))
            VStack(alignment: .leading) {
                Text(accessory.name).font(.system(size: 10, weight: .bold))
                if !isOwned {
                    Text("$\(accessory.price)").font(.system(size: 8)).foregroundColor(.yellow)
                }
            }
            Spacer()
            Button(action: {
                if isOwned { viewModel.currentAccessoryName = accessory.name }
                else { viewModel.buyAccessory(accessory) }
            }) {
                ActionLabel(isEquipped: isEquipped, isOwned: isOwned, canAfford: viewModel.totalMoney >= accessory.price)
            }
            .buttonStyle(.plain)
            .disabled(isEquipped || (!isOwned && viewModel.totalMoney < accessory.price))
        }
    }
}

private struct UpgradeRow: View {
    let item: Upgrade
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        let isOwned = viewModel.ownedUpgrades.contains(item.name)
        let count = viewModel.consumables[item.name, default: 0]
        
        HStack {
            VStack(alignment: .leading) {
                Text(item.name).font(.system(size: 10, weight: .bold))
                Text("$\(item.price)").font(.system(size: 8)).foregroundColor(.yellow)
            }
            Spacer()
            Button(action: { viewModel.infoAlert = item }) {
                Image(systemName: "info.circle").foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)
            
            Button(action: { viewModel.buyUpgrade(item) }) {
                Text(item.isConsumable ? "+\(count)" : (isOwned ? "КУПЛЕНО" : "КУПИТИ"))
                    .font(.system(size: 7, weight: .bold))
                    .padding(4)
                    .background(viewModel.totalMoney >= item.price ? Color.blue : Color.gray)
                    .cornerRadius(4)
            }
            .disabled(!item.isConsumable && isOwned || viewModel.totalMoney < item.price)
        }
    }
}

private struct ActionLabel: View {
    let isEquipped: Bool
    let isOwned: Bool
    let canAfford: Bool
    
    var body: some View {
        if isEquipped {
            Text("ОДЯГНУТО").font(.system(size: 7, weight: .bold)).foregroundColor(.green)
        } else if isOwned {
            Text("ОДЯГТИ").font(.system(size: 7, weight: .bold)).foregroundColor(.white)
        } else {
            Text("КУПИТИ")
                .font(.system(size: 7, weight: .bold))
                .padding(4)
                .background(canAfford ? Color.blue : Color.gray)
                .cornerRadius(4)
        }
    }
}
