import SwiftUI

/// Shop screen for buying gadgets and customization.
struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: -1) {
                    Text("$\(viewModel.session.totalMoney)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Balance \(viewModel.session.totalMoney) dollars")
                    Text(viewModel.session.playerRank)
                        .font(.system(size: 9))
                        .foregroundStyle(.blue)
                        .italic()
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel("Rank \(viewModel.session.playerRank)")
                }
                Spacer()
            }
            .padding(.leading, 22)
            .padding(.trailing, 44)
            .padding(.top, 6)

            HStack {
                Button(action: { viewModel.close() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.3), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Map")
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.top, 2)

            List {
                Section(header: Text("АКСЕСУАРИ").font(.system(size: 9))) {
                    ForEach(viewModel.session.accessories) { acc in
                        AccessoryRow(accessory: acc, viewModel: viewModel)
                    }
                }

                Section(header: Text("ГАДЖЕТИ").font(.system(size: 9))) {
                    ForEach(viewModel.session.shopItems) { item in
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
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        let isOwned = viewModel.session.ownedAccessories.contains(accessory.id)
        let isEquipped = viewModel.session.currentAccessoryName == accessory.name

        HStack {
            Text(accessory.icon)
                .font(.system(size: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(accessory.name).font(.system(size: 10, weight: .bold))
                if !isOwned {
                    Text("$\(accessory.price)")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                        .accessibilityLabel("Price \(accessory.price) dollars")
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
            .accessibilityLabel(isEquipped ? "Equipped" : (isOwned ? "Equip \(accessory.name)" : "Buy \(accessory.name) for \(accessory.price) dollars"))
        }
    }
}

private struct UpgradeRow: View {
    let item: Upgrade
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        let isOwned = viewModel.session.ownedUpgrades.contains(item.id)
        let count = viewModel.session.consumables[item.id, default: 0]

        HStack {
            VStack(alignment: .leading) {
                Text(item.name).font(.system(size: 10, weight: .bold))
                Text("$\(item.price)")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
                    .accessibilityLabel("Price \(item.price) dollars")
            }
            Spacer()
            Button(action: { viewModel.showInfo(item) }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .accessibilityLabel("Item Information")
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)

            Button(action: { viewModel.buyUpgrade(item) }) {
                Text(item.isConsumable ? "+\(count)" : (isOwned ? "КУПЛЕНО" : "КУПИТИ"))
                    .font(.system(size: 9, weight: .bold))
                    .padding(4)
                    .background(viewModel.session.totalMoney >= item.price ? Color.blue : Color.gray)
                    .cornerRadius(4)
            }
            .disabled(!item.isConsumable && isOwned || viewModel.session.totalMoney < item.price)
            .accessibilityLabel(item.isConsumable ? "You have \(count). Buy more for \(item.price) dollars" : (isOwned ? "Already owned" : "Buy \(item.name) for \(item.price) dollars"))
        }
    }
}

private struct ActionLabel: View {
    let isEquipped: Bool
    let isOwned: Bool
    let canAfford: Bool

    var body: some View {
        if isEquipped {
            Text("ОДЯГНУТО").font(.system(size: 9, weight: .bold)).foregroundColor(.green)
        } else if isOwned {
            Text("ОДЯГТИ").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
        } else {
            Text("КУПИТИ")
                .font(.system(size: 9, weight: .bold))
                .padding(4)
                .background(canAfford ? Color.blue : Color.gray)
                .cornerRadius(4)
        }
    }
}
