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
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                VStack(spacing: 15) {
                    Text("СИГНАЛІЗАЦІЯ")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .accessibilityAddTraits(.isHeader)

                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: w * 0.8, height: 20)
                            .cornerRadius(10)
                        Rectangle()
                            .fill(Color.green.opacity(0.5))
                            .frame(width: w * 0.2, height: 20)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4, height: 26)
                            .offset(x: CGFloat(viewModel.hackPosition) * (w * 0.4))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Hacking meter. Target is in the center.")

                    Button("ХАКНУТИ") { viewModel.performHack() }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .accessibilityLabel("Perform hack")

                    if (viewModel.session.consumables[.emp] ?? 0) > 0 {
                        Button("ЕМІ (-1)") { viewModel.useEMP() }
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .accessibilityLabel("Use EMP. You have \(viewModel.session.consumables[.emp, default: 0]) left.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if !viewModel.session.seenCoachMarks.contains(CoachMarkID.hacking) {
                CoachMarkView(
                    icon: "hand.tap.fill",
                    instruction: "Tap the button when the needle is in the green zone",
                    onDismiss: {
                        viewModel.session.markCoachMarkSeen(CoachMarkID.hacking)
                    }
                )
                .transition(.opacity)
            }
        }
        .onReceive(tick) { _ in viewModel.tick() }
    }
}
