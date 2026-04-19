import SwiftUI

/// Main navigation screen showing available districts.
struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    
    // Timer for alternating between Money and Steps in HUD
    @State private var showSteps = false
    private let hudTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            // Content Layer
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
            .padding(.top, 18)

            // Floating Header Layer (Alternating HUD)
            HStack(alignment: .center) {
                Button(action: { viewModel.openShop() }) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Shop")
                
                ZStack(alignment: .leading) {
                    if showSteps {
                        // Steps Display
                        VStack(alignment: .leading, spacing: -2) {
                            HStack(spacing: 2) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 10))
                                Text("\(viewModel.session.todaySteps)")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.green)
                            
                            Text("КРОКИ ЗА СЬОГОДНІ")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(.gray)
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .move(edge: .top))))
                        .onTapGesture {
                            // Developer Cheat: Add 1000 steps per tap
                            viewModel.session.todaySteps += 1000
                        }
                    } else {
                        // Money Display
                        VStack(alignment: .leading, spacing: -2) {
                            Text("$\(viewModel.session.totalMoney)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.yellow)
                            Text(viewModel.session.playerRank)
                                .font(.system(size: 7))
                                .foregroundStyle(.blue)
                                .italic()
                                .lineLimit(1)
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .move(edge: .top))))
                    }
                }
                .id(showSteps) // Force transition
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.top, -4)
        }
        .ignoresSafeArea(.container, edges: .top)
        .onReceive(hudTimer) { _ in
            withAnimation(.spring(duration: 0.5)) {
                showSteps.toggle()
            }
        }
        .onAppear {
            viewModel.session.refreshHealthData()
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
            ZStack {
                if let deduction = viewModel.session.activeDeduction {
                    Text("-$\(deduction.amount) \(deduction.reason)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                        .offset(y: -20)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .zIndex(1)
                }

                Text(district.name.uppercased())
                    .font(.system(size: 14, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .accessibilityAddTraits(.isHeader)
            }

            if isUnlocked {
                UnlockedDistrictContent(district: district, viewModel: viewModel)
            } else {
                LockedDistrictContent(district: district, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

private struct UnlockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 3) {
            Text("Рівень \(viewModel.session.districtProgress[district.id, default: 0] + 1)")
                .font(.system(size: 9))
                .foregroundColor(.gray)

            Button(action: { viewModel.toggleBribe() }) {
                HStack(spacing: 3) {
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

            Button(action: { viewModel.startMission() }) {
                Text("ПОЧАТИ")
                    .font(.system(size: 11, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
            .padding(.horizontal, 12)
        }
    }
}

private struct LockedDistrictContent: View {
    let district: District
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 2) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("$\(district.unlockPrice)")
                }
                .foregroundColor(viewModel.session.totalMoney >= district.unlockPrice ? .yellow : .gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                    Text("\(district.unlockSteps)")
                }
                .foregroundColor(viewModel.session.todaySteps >= district.unlockSteps ? .green : .gray)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))

            Button(action: { viewModel.unlockDistrict(district) }) {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text("ВІДКРИТИ")
                }
                .font(.system(size: 10, weight: .black))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!viewModel.session.economyService.canUnlockDistrict(totalMoney: viewModel.session.totalMoney, currentSteps: viewModel.session.todaySteps, district: district))
            .controlSize(.small)
            .padding(.horizontal, 12)
        }
    }
}
