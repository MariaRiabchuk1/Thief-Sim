import SwiftUI

/// Main navigation screen showing available districts.
struct MapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: -1) {
                    Text("$\(viewModel.session.totalMoney)")
                        .font(.system(size: 14, weight: .bold)) // Slightly increased
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Balance \(viewModel.session.totalMoney) dollars")
                    Text(viewModel.session.playerRank)
                        .font(.system(size: 9)) // 9pt floor
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

            TabView(selection: $viewModel.selectedDistrictIndex) {
                ForEach(0..<viewModel.session.districts.count, id: \.self) { index in
                    DistrictCard(index: index, viewModel: viewModel)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .overlay(alignment: .topLeading) {
                Button(action: { viewModel.openShop() }) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.3), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Shop")
                .padding(.leading, 4)
                .padding(.top, 2)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

/// A card representing a single district in the map.
private struct DistrictCard: View {
    let index: Int
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        let district = viewModel.session.districts[index]
        let isUnlocked = viewModel.session.unlockedDistricts.contains(district.name)

        VStack(spacing: 4) {
            Text(district.name)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if isUnlocked {
                UnlockedDistrictContent(district: district, viewModel: viewModel)
            } else {
                LockedDistrictContent(district: district, viewModel: viewModel)
            }
        }
    }
}

private struct UnlockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("Прогрес: Рівень \(viewModel.session.districtProgress[district.name, default: 0] + 1)")
                .font(.system(size: 9)) // 9pt floor
                .foregroundColor(.gray)

            Button(action: { viewModel.toggleBribe() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.bribeActive ? "hand.thumbsup.fill" : "dollarsign.circle")
                    Text(viewModel.bribeActive ? "ПІДКУПЛЕНО" : "ПІДКУП $\(district.reward/4)")
                }
                .font(.system(size: 9, weight: .bold)) // Ensure min size
                .foregroundColor(viewModel.bribeActive ? .green : .white)
            }
            .buttonStyle(.bordered)
            .tint(viewModel.bribeActive ? .green : .gray)
            .controlSize(.small)
            .accessibilityLabel(viewModel.bribeActive ? "Bribe active" : "Pay bribe \(district.reward/4) dollars")

            Button("ПОЧАТИ") { viewModel.startMission() }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
                .accessibilityLabel("Start mission in \(district.name)")
        }
    }
}

private struct LockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            Text("Ціна: $\(district.unlockPrice)")
                .font(.system(size: 10, weight: .bold))
                .accessibilityLabel("Unlock price \(district.unlockPrice) dollars")
            Button("РОЗБЛОКУВАТИ") { viewModel.unlockDistrict(district) }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.session.totalMoney < district.unlockPrice)
                .controlSize(.small)
        }
    }
}
