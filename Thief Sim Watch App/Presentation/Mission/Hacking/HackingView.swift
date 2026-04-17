import SwiftUI
import Combine

/// Minigame: hacking the alarm system.
struct HackingView: View {
    @StateObject private var viewModel: HackingViewModel

    init(coordinator: MissionCoordinator) {
        _viewModel = StateObject(wrappedValue: HackingViewModel(coordinator: coordinator))
    }

    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 15) {
            Text("СИГНАЛІЗАЦІЯ")
                .font(.system(size: 11, weight: .bold)) // Increased from caption
                .foregroundColor(.red)
                .accessibilityAddTraits(.isHeader)

            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .cornerRadius(10)
                Rectangle()
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 30, height: 20)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 26)
                    .offset(x: CGFloat(viewModel.hackPosition))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hacking meter. Target is in the center.")

            Button("ХАКНУТИ") { viewModel.performHack() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .accessibilityLabel("Perform hack")

            if (viewModel.session.consumables[.emp] ?? 0) > 0 {
                Button("ЕМІ (-1)") { viewModel.useEMP() }
                    .font(.system(size: 10)) // 9pt floor
                    .foregroundColor(.orange)
                    .accessibilityLabel("Use EMP. You have \(viewModel.session.consumables[.emp, default: 0]) left.")
            }
        }
        .onReceive(tick) { _ in viewModel.tick() }
    }
}
