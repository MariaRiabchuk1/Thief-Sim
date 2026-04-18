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

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                VStack(spacing: 0) {
                    Header(coordinator: coordinator, onSmokeBomb: { viewModel.useSmokeBomb() })
                    
                    DetectionBar(level: coordinator.detectionLevel)
                        .padding(.top, 2)

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
                                baseSize: size * 0.65 // Slightly smaller to fit the bar
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

            if !coordinator.session.seenCoachMarks.contains(CoachMarkID.safeCracking) {
                CoachMarkView(
                    icon: "safe.fill",
                    instruction: "Rotate dial to find the combo. Avoid patrol. Tap quickly if lock is stuck.",
                    onDismiss: {
                        coordinator.session.markCoachMarkSeen(CoachMarkID.safeCracking)
                    }
                )
                .transition(.opacity)
            }
        }
        .focusable()
        .digitalCrownRotation($viewModel.crownValue, from: 0, through: 100, by: 0.5, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: false)
        .onAppear {
            viewModel.crownValue = 50
        }
        .onChange(of: viewModel.crownValue) { _, newValue in
            viewModel.handleSafeInput(newValue)
        }
        .task {
            // Local 1s ticker driven by the clock abstraction.
            while !Task.isCancelled {
                coordinator.handleSafePhaseTick()
                try? await coordinator.clock.sleep(seconds: 1.0)
            }
        }
    }
}

private struct DetectionBar: View {
    let level: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                Capsule()
                    .fill(level > 0.7 ? Color.red : Color.orange)
                    .frame(width: geo.size.width * CGFloat(level))
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
        .accessibilityLabel("Detection level")
        .accessibilityValue("\(Int(level * 100)) percent")
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
            
            // Replaced the pulsing heart with the thin bar above, 
            // but keeping a small static heart for thematic consistency
            Image(systemName: "heart.fill")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .accessibilityHidden(true)
            
            Spacer()
            Image(systemName: coordinator.isPatrolActive ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill")
                .foregroundColor(coordinator.isPatrolActive ? .red : (coordinator.detectionLevel > 0.7 ? .orange : .blue.opacity(0.5)))
                .accessibilityLabel(coordinator.isPatrolActive ? "Patrol active! Don't move." : "Patrol is away")
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
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
                // Use a safe modulo to prevent Int overflow
                let time = context.date.timeIntervalSinceReferenceDate
                let seed = Int((time.truncatingRemainder(dividingBy: 1000000)) * 100)
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
                .fill(LinearGradient(
                    colors: isTreasureLevel ? [.yellow.opacity(0.8), .orange.opacity(0.4), .black] : [.gray, .black],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: baseSize * 0.75, height: baseSize * 0.75)
                .rotationEffect(.degrees(crownValue * 3.6))

            Rectangle()
                .fill(resonanceAlpha > 0.8 ? Color.green : (isTreasureLevel ? Color.yellow : Color.red))
                .frame(width: baseSize * 0.035, height: baseSize * 0.1)
                .offset(y: -baseSize * 0.33)
                .rotationEffect(.degrees(crownValue * 3.6))
        }
        .frame(width: baseSize, height: baseSize)
        .modifier(TensionShake(detectionLevel: detectionLevel, active: !isPatrolActive))
        .overlay {
            if isTreasureLevel {
                Circle()
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    .blur(radius: 2)
            }
        }
    }
}
