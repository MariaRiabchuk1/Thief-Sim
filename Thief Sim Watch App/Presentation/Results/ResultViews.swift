import SwiftUI

/// Screen shown after a successful mission.
struct SuccessView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        let baseReward = viewModel.activeDistrict?.reward ?? 0
        let reward = viewModel.isTreasureLevel ? baseReward * 2 : baseReward

        VStack(spacing: 10) {
            Image(systemName: viewModel.isTreasureLevel ? "sparkles" : "banknote.fill")
                .font(.largeTitle)
                .foregroundColor(viewModel.isTreasureLevel ? .yellow : .green)
            
            Text("УСПІХ!").font(.headline)
            Text("+ $\(reward)").foregroundColor(.green).bold()
            
            Button("ВТІКТИ") {
                viewModel.finishMission(success: true)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

/// Screen shown after being caught.
struct CaughtView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("ВАС СПІЙМАНО!").font(.headline)
            
            Button("ЗДАТИСЯ") {
                viewModel.finishMission(success: false)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
