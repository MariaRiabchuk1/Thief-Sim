import SwiftUI
import Combine

/// Minigame: cracking the safe.
struct SafeCrackingView: View {
    @StateObject private var viewModel: SafeCrackingViewModel
    @ObservedObject private var coordinator: MissionCoordinator

    init(coordinator: MissionCoordinator) {
        self._coordinator = ObservedObject(wrappedValue: coordinator)
        _viewModel = StateObject(wrappedValue: SafeCrackingViewModel(coordinator: coordinator))
    }

    private let globalTick = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            VStack(spacing: 0) {
                Header(coordinator: coordinator, onSmokeBomb: { viewModel.useSmokeBomb() })
                Spacer()

                ZStack {
                    if coordinator.isLockStuck {
                        StuckLockView()
                    } else {
                        SafeDialView(
                            crownValue: viewModel.crownValue,
                            resonanceAlpha: viewModel.resonanceAlpha,
                            isPatrolActive: coordinator.isPatrolActive,
                            detectionLevel: coordinator.detectionLevel,
                            isTreasureLevel: coordinator.isTreasureLevel,
                            hasStethoscope: coordinator.hasStethoscope,
                            baseSize: size * 0.7
                        )
                    }
                }
                .contentShape(Circle())
                .onTapGesture {
                    if coordinator.isLockStuck {
                        viewModel.tapStuckLock()
                    }
                }

                Spacer()
                Footer(coordinator: coordinator, onCrack: { viewModel.tryCrackSafe() })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .digitalCrownRotation($viewModel.crownValue, from: 0, through: 100, by: 0.5, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: false)
        .onAppear {
            viewModel.crownValue = 50
        }
        .onChange(of: viewModel.crownValue) { _, newValue in
            viewModel.handleSafeInput(newValue)
        }
        .onReceive(globalTick) { _ in coordinator.handleSafePhaseTick() }
    }
}

private struct Header: View {
    @ObservedObject var coordinator: MissionCoordinator
    let onSmokeBomb: () -> Void

    var body: some View {
        HStack {
            if coordinator.timeRemaining > 0 {
                Text("\(coordinator.timeRemaining)с")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(coordinator.timeRemaining < 10 ? .red : .orange)
                    .accessibilityLabel("Time remaining \(coordinator.timeRemaining) seconds")
            }

            if (coordinator.session.consumables[.smokeBomb] ?? 0) > 0 {
                Button(action: onSmokeBomb) {
                    HStack(spacing: 2) {
                        Image(systemName: "wind")
                        Text("\(coordinator.session.consumables[.smokeBomb, default: 0])")
                            .font(.system(size: 9)) // 9pt floor
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                .accessibilityLabel("Use smoke bomb. You have \(coordinator.session.consumables[.smokeBomb, default: 0])")
            }

            Spacer()
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .scaleEffect(1.0 + coordinator.detectionLevel * 0.4)
                .accessibilityLabel("Health")
                .accessibilityValue("\(Int((1.0 - coordinator.detectionLevel) * 100)) percent")
            Spacer()
            Image(systemName: coordinator.isPatrolActive ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill")
                .foregroundColor(coordinator.isPatrolActive ? .red : (coordinator.detectionLevel > 0.7 ? .orange : .blue.opacity(0.5)))
                .accessibilityLabel(coordinator.isPatrolActive ? "Patrol active! Don't move." : "Patrol is away")
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
    }
}

private struct Footer: View {
    @ObservedObject var coordinator: MissionCoordinator
    let onCrack: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                ForEach(0..<coordinator.district.codeLength, id: \.self) { i in
                    Circle()
                        .fill(i < coordinator.currentStep ? Color.green : Color.gray)
                        .frame(width: 5, height: 5)
                }
            }
            .accessibilityLabel("Combination progress: \(coordinator.currentStep) of \(coordinator.district.codeLength) steps complete")
            
            if !coordinator.isLockStuck {
                Button("ЗЛАМАТИ", action: onCrack)
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
                    .accessibilityLabel("Try to crack the safe")
            }
        }
        .padding(.bottom, 5)
    }
}

private struct StuckLockView: View {
    var body: some View {
        VStack {
            Text("ЗАЇЛО!")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.orange)
            Text("ТАПАЙ ШВИДКО")
                .font(.system(size: 9)) // 9pt floor
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lock is stuck! Tap quickly to release.")
    }
}

/// Clock-driven shake so it doesn't re-roll the offset on every crown tick.
/// Kicks in only past a detection floor, so calm play is rock-steady.
private struct TensionShake: ViewModifier {
    let detectionLevel: Double
    let active: Bool

    func body(content: Content) -> some View {
        let amplitude = max(0, (detectionLevel - 0.5) * 10)
        if !active || amplitude == 0 {
            content
        } else {
            TimelineView(.periodic(from: .now, by: 0.12)) { context in
                let seed = Int(context.date.timeIntervalSinceReferenceDate * 10)
                var rng = SeededShakeRNG(seed: UInt64(bitPattern: Int64(seed)))
                let offset = CGFloat.random(in: -amplitude...amplitude, using: &rng)
                content.offset(x: offset)
            }
        }
    }
}

private struct SeededShakeRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private struct SafeDialView: View {
    let crownValue: Double
    let resonanceAlpha: Double
    let isPatrolActive: Bool
    let detectionLevel: Double
    let isTreasureLevel: Bool
    let hasStethoscope: Bool
    let baseSize: CGFloat

    var body: some View {
        ZStack {
            if isPatrolActive {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: baseSize * 1.1, height: baseSize * 1.1)
                    .blur(radius: 5)
            }

            let boost = hasStethoscope ? 1.5 : 1.0
            Circle()
                .stroke(isTreasureLevel ? Color.yellow : Color.blue, lineWidth: 2)
                .scaleEffect(1.0 + resonanceAlpha * 0.3 * boost)
                .opacity(resonanceAlpha)

            Circle()
                .fill(RadialGradient(colors: [.gray.opacity(0.2), .black], center: .center, startRadius: 0, endRadius: baseSize / 2))

            Circle()
                .fill(LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom))
                .frame(width: baseSize * 0.75, height: baseSize * 0.75)
                .rotationEffect(.degrees(crownValue * 3.6))

            Rectangle()
                .fill(resonanceAlpha > 0.8 ? Color.green : Color.red)
                .frame(width: baseSize * 0.035, height: baseSize * 0.1)
                .offset(y: -baseSize * 0.33)
                .rotationEffect(.degrees(crownValue * 3.6))
        }
        .frame(width: baseSize, height: baseSize)
        .modifier(TensionShake(detectionLevel: detectionLevel, active: !isPatrolActive))
    }
}
