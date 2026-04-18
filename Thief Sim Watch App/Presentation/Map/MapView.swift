import SwiftUI

/// Main navigation screen showing available districts.
struct MapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(alignment: .center) {
                Button(action: { viewModel.openShop() }) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.3), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Shop")
                
                VStack(alignment: .leading, spacing: -1) {
                    Text("$\(viewModel.session.totalMoney)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Balance \(viewModel.session.totalMoney) dollars")
                    Text(viewModel.session.playerRank)
                        .font(.system(size: 8)) // Scaled down for safe areas
                        .foregroundStyle(.blue)
                        .italic()
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel("Rank \(viewModel.session.playerRank)")
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            TabView(selection: Binding(
                get: { viewModel.selectedDistrictIndex },
                set: { viewModel.didSelectDistrict(at: $0) }
            )) {
                ForEach(0..<viewModel.session.districts.count, id: \.self) { index in
                    DistrictCard(index: index, viewModel: viewModel)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}

/// A card representing a single district in the map.
private struct DistrictCard: View {
    let index: Int
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        let district = viewModel.session.districts[index]
        let isUnlocked = viewModel.session.unlockedDistricts.contains(district.id)

        VStack(spacing: 4) {
            Text(district.name.uppercased())
                .font(.system(size: 14, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .accessibilityAddTraits(.isHeader)

            if isUnlocked {
                UnlockedDistrictContent(district: district, viewModel: viewModel)
            } else {
                LockedDistrictContent(district: district, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct UnlockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("Рівень \(viewModel.session.districtProgress[district.id, default: 0] + 1)")
                .font(.system(size: 9))
                .foregroundColor(.gray)

            Button(action: { viewModel.toggleBribe() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.bribeActive ? "hand.thumbsup.fill" : "dollarsign.circle")
                    Text(viewModel.bribeActive ? "ПІДКУПЛЕНО" : "ПІДКУП $\(district.reward/4)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(viewModel.bribeActive ? .green : .white)
            }
            .buttonStyle(.bordered)
            .tint(viewModel.bribeActive ? .green : .gray)
            .controlSize(.small)
            .accessibilityLabel(viewModel.bribeActive ? "Bribe active" : "Pay bribe \(district.reward/4) dollars")

            Button(action: { viewModel.startMission() }) {
                Text("ПОЧАТИ")
                    .font(.system(size: 11, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
            .padding(.horizontal, 16)
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
            Text("$\(district.unlockPrice)")
                .font(.system(size: 11, weight: .bold))
                .accessibilityLabel("Unlock price \(district.unlockPrice) dollars")
            Button("РОЗБЛОКУВАТИ") { viewModel.unlockDistrict(district) }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.session.totalMoney < district.unlockPrice)
                .controlSize(.small)
                .padding(.horizontal, 10)
        }
    }
}
