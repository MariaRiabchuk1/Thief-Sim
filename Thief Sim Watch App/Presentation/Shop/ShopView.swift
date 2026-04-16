import SwiftUI

/// Shop screen for buying gadgets and customization.
struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        VStack(spacing: 0) {
            Header(money: viewModel.session.totalMoney) { viewModel.close() }

            List {
                Section(header: Text("АКСЕСУАРИ").font(.system(size: 8))) {
                    ForEach(viewModel.session.accessories) { acc in
                        AccessoryRow(accessory: acc, viewModel: viewModel)
                    }
                }

                Section(header: Text("ГАДЖЕТИ").font(.system(size: 8))) {
                    ForEach(viewModel.session.shopItems) { item in
                        UpgradeRow(item: item, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

private struct Header: View {
    let money: Int
    let onBack: () -> Void

    var body: some View {
        HStack {
            Text("$\(money)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Spacer()
            Button(action: onBack) {
                Text("НАЗАД")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 5)
        .padding(.bottom, 2)
    }
}

private struct AccessoryRow: View {
    let accessory: Accessory
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        let isOwned = viewModel.session.ownedAccessories.contains(accessory.name)
        let isEquipped = viewModel.session.currentAccessoryName == accessory.name

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
                if isOwned { viewModel.equipAccessory(accessory) }
                else { viewModel.buyAccessory(accessory) }
            }) {
                ActionLabel(isEquipped: isEquipped, isOwned: isOwned, canAfford: viewModel.session.totalMoney >= accessory.price)
            }
            .buttonStyle(.plain)
            .disabled(isEquipped || (!isOwned && viewModel.session.totalMoney < accessory.price))
        }
    }
}

private struct UpgradeRow: View {
    let item: Upgrade
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        let isOwned = viewModel.session.ownedUpgrades.contains(item.name)
        let count = viewModel.session.consumables[item.name, default: 0]

        HStack {
            VStack(alignment: .leading) {
                Text(item.name).font(.system(size: 10, weight: .bold))
                Text("$\(item.price)").font(.system(size: 8)).foregroundColor(.yellow)
            }
            Spacer()
            Button(action: { viewModel.showInfo(item) }) {
                Image(systemName: "info.circle").foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)

            Button(action: { viewModel.buyUpgrade(item) }) {
                Text(item.isConsumable ? "+\(count)" : (isOwned ? "КУПЛЕНО" : "КУПИТИ"))
                    .font(.system(size: 7, weight: .bold))
                    .padding(4)
                    .background(viewModel.session.totalMoney >= item.price ? Color.blue : Color.gray)
                    .cornerRadius(4)
            }
            .disabled(!item.isConsumable && isOwned || viewModel.session.totalMoney < item.price)
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
