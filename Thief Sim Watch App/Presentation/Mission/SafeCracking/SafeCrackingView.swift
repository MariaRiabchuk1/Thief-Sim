import SwiftUI

/// Minigame: cracking the safe.
struct SafeCrackingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Header(viewModel: viewModel)
            Spacer()
            
            ZStack {
                if viewModel.isLockStuck {
                    StuckLockView(stuckProgress: $viewModel.stuckProgress, isLockStuck: $viewModel.isLockStuck)
                } else {
                    SafeDialView(
                        crownValue: viewModel.crownValue,
                        resonanceAlpha: viewModel.resonanceAlpha,
                        isPatrolActive: viewModel.isPatrolActive,
                        detectionLevel: viewModel.detectionLevel,
                        isTreasureLevel: viewModel.isTreasureLevel,
                        hasStethoscope: viewModel.session.ownedUpgrades.contains("Стетоскоп")
                    )
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                if viewModel.isLockStuck {
                    viewModel.stuckProgress += 1
                    if viewModel.stuckProgress >= 5 {
                        viewModel.isLockStuck = false
                        viewModel.stuckProgress = 0
                    }
                }
            }
            
            Spacer()
            Footer(viewModel: viewModel)
        }
        .focusable()
        .digitalCrownRotation($viewModel.crownValue, from: 0, through: 100, by: 0.5, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: false)
        .onChange(of: viewModel.crownValue) { _, newValue in
            viewModel.handleSafeInput(newValue)
        }
    }
}

private struct Header: View {
    @ObservedObject var viewModel: GameViewModel
    var body: some View {
        HStack {
            if viewModel.timeRemaining > 0 {
                Text("\(viewModel.timeRemaining)с")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(viewModel.timeRemaining < 10 ? .red : .orange)
            }
            
            if (viewModel.session.consumables["Дим. шашка"] ?? 0) > 0 {
                Button(action: { viewModel.useSmokeBomb() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "wind")
                        Text("\(viewModel.session.consumables["Дим. шашка", default: 0])")
                            .font(.system(size: 8))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
            }
            
            Spacer()
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .scaleEffect(1.0 + viewModel.detectionLevel * 0.4)
            Spacer()
            Image(systemName: viewModel.isPatrolActive ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill")
                .foregroundColor(viewModel.isPatrolActive ? .red : (viewModel.detectionLevel > 0.7 ? .orange : .blue.opacity(0.5)))
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
    }
}

private struct Footer: View {
    @ObservedObject var viewModel: GameViewModel
    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                ForEach(0..<viewModel.currentDistrict.codeLength, id: \.self) { i in
                    Circle()
                        .fill(i < viewModel.currentStep ? Color.green : Color.gray)
                        .frame(width: 5, height: 5)
                }
            }
            if !viewModel.isLockStuck {
                Button("ЗЛАМАТИ") { viewModel.tryCrackSafe() }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
            }
        }
        .padding(.bottom, 5)
    }
}

private struct StuckLockView: View {
    @Binding var stuckProgress: Int
    @Binding var isLockStuck: Bool
    var body: some View {
        VStack {
            Text("ЗАЇЛО!")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.orange)
            Text("ТАПАЙ ШВИДКО")
                .font(.system(size: 8))
        }
    }
}

private struct SafeDialView: View {
    let crownValue: Double
    let resonanceAlpha: Double
    let isPatrolActive: Bool
    let detectionLevel: Double
    let isTreasureLevel: Bool
    let hasStethoscope: Bool
    
    var body: some View {
        ZStack {
            if isPatrolActive {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 95, height: 95)
                    .blur(radius: 5)
            }
            
            let boost = hasStethoscope ? 1.5 : 1.0
            Circle()
                .stroke(isTreasureLevel ? Color.yellow : Color.blue, lineWidth: 2)
                .scaleEffect(1.0 + resonanceAlpha * 0.3 * boost)
                .opacity(resonanceAlpha)
            
            Circle()
                .fill(RadialGradient(colors: [.gray.opacity(0.2), .black], center: .center, startRadius: 0, endRadius: 50))
            
            Circle()
                .fill(LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom))
                .frame(width: 65, height: 65)
                .rotationEffect(.degrees(crownValue * 3.6))
            
            Rectangle()
                .fill(resonanceAlpha > 0.8 ? Color.green : Color.red)
                .frame(width: 3, height: 8)
                .offset(y: -28)
                .rotationEffect(.degrees(crownValue * 3.6))
        }
        .frame(width: 85, height: 85)
        .offset(x: isPatrolActive ? 0 : CGFloat.random(in: CGFloat(-detectionLevel*5)...CGFloat(detectionLevel*5)))
    }
}
