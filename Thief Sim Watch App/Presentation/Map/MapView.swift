import SwiftUI

/// Main navigation screen showing available districts.
struct MapView: View {
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

            TabView(selection: $viewModel.selectedDistrictIndex) {
                ForEach(0..<viewModel.districts.count, id: \.self) { index in
                    DistrictCard(index: index, viewModel: viewModel)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .overlay(alignment: .topLeading) {
                Button(action: { viewModel.gameState = .shop }) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.3), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
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
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        let district = viewModel.districts[index]
        let isUnlocked = viewModel.unlockedDistricts.contains(district.name)
        
        VStack(spacing: 4) {
            Text(district.name).font(.headline)
            
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
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Прогрес: Рівень \(viewModel.districtProgress[district.name, default: 0] + 1)")
                .font(.system(size: 8))
                .foregroundColor(.gray)
            
            Button(action: { viewModel.toggleBribe() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.bribeActive ? "hand.thumbsup.fill" : "dollarsign.circle")
                    Text(viewModel.bribeActive ? "ПІДКУПЛЕНО" : "ПІДКУП $\(district.reward/4)")
                }
                .foregroundColor(viewModel.bribeActive ? .green : .white)
            }
            .buttonStyle(.bordered)
            .tint(viewModel.bribeActive ? .green : .gray)
            .controlSize(.small)

            Button("ПОЧАТИ") { viewModel.startMission() }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
        }
    }
}

private struct LockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "lock.fill").foregroundColor(.orange)
            Text("Ціна: $\(district.unlockPrice)").font(.system(size: 10, weight: .bold))
            Button("РОЗБЛОКУВАТИ") { viewModel.unlockDistrict(district) }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.totalMoney < district.unlockPrice)
                .controlSize(.small)
        }
    }
}
