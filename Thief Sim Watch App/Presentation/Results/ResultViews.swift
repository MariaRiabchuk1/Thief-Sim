import SwiftUI

/// Screen shown after a successful mission.
struct SuccessView: View {
    @ObservedObject var coordinator: MissionCoordinator

    var body: some View {
        let reward = coordinator.rewardPreview

        VStack(spacing: 10) {
            Image(systemName: coordinator.isTreasureLevel ? "sparkles" : "banknote.fill")
                .font(.largeTitle)
                .foregroundColor(coordinator.isTreasureLevel ? .yellow : .green)
                .accessibilityLabel(coordinator.isTreasureLevel ? "Sparkles" : "Banknote")

            Text("УСПІХ!").font(.headline)
            Text("+ $\(reward)")
                .foregroundColor(.green)
                .bold()
                .accessibilityLabel("Reward \(reward) dollars")

            Button("ВТІКТИ") {
                coordinator.finish(success: true)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .accessibilityLabel("Escape and collect reward")
        }
        .onAppear {
            if coordinator.isTreasureLevel {
                coordinator.hapticProvider.play(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.hapticProvider.play(.notification)
                }
            }
        }
    }
}

/// Screen shown after being caught.
struct CaughtView: View {
    @ObservedObject var coordinator: MissionCoordinator

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
                .accessibilityHidden(true)

            Text("ВАС СПІЙМАНО!")
                .font(.headline)
                .accessibilityLabel("You were caught!")

            Button("ЗДАТИСЯ") {
                coordinator.finish(success: false)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityLabel("Surrender and lose half your money")
        }
    }
}
