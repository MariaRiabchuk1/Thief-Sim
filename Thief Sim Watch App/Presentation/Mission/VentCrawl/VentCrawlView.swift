import SwiftUI
import Combine

/// Minigame: crawling through the vent.
///
/// Maps the engine's normalized coordinates to actual view pixels via
/// `GeometryReader`, so layout scales with the watch size.
struct VentCrawlView: View {
    @StateObject private var viewModel: VentCrawlViewModel

    init(coordinator: MissionCoordinator) {
        _viewModel = StateObject(wrappedValue: VentCrawlViewModel(coordinator: coordinator))
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let size = geo.size
                ZStack(alignment: .topLeading) {
                    Color.black
                    BackgroundGrid(progress: viewModel.state.progress)

                    ForEach(viewModel.state.bullets) { bullet in
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 3, height: 3)
                            .position(x: bullet.x * size.width, y: bullet.y * size.height)
                    }

                    ForEach(viewModel.state.obstacles) { obs in
                        ObstacleView(obstacle: obs, size: size)
                    }

                    PlayerFigureView(
                        skinColor: viewModel.session.currentSkin.color,
                        accessory: viewModel.session.currentAccessory
                    )
                    .position(
                        x: viewModel.state.playerX * size.width,
                        y: VentCrawlMetrics.playerCenterY * size.height
                    )

                    HUD(level: viewModel.coordinator.level + 1, progress: viewModel.state.progress)
                }
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }

            if !viewModel.session.seenCoachMarks.contains(CoachMarkID.ventCrawl) {
                CoachMarkView(
                    icon: "crown.fill",
                    instruction: "Rotate crown to switch lanes and dodge obstacles",
                    onDismiss: {
                        viewModel.session.markCoachMarkSeen(CoachMarkID.ventCrawl)
                    }
                )
                .transition(.opacity)
            }
        }
        .focusable()
        .digitalCrownRotation(
            $viewModel.state.playerX,
            from: VentCrawlMetrics.laneMin,
            through: VentCrawlMetrics.laneMax,
            by: 0.005,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: false
        )
        .onAppear {
            viewModel.state.playerX = 0.5
        }
        .task {
            // Local 50ms ticker driven by the clock abstraction.
            while !Task.isCancelled {
                viewModel.tick()
                try? await viewModel.clock.sleep(seconds: 0.05)
            }
        }
    }
}

private struct BackgroundGrid: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            let spacing = geo.size.height / 6
            let offset = (progress * geo.size.height * 4).truncatingRemainder(dividingBy: spacing)
            VStack(spacing: 0) {
                ForEach(0..<6) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * spacing + offset)
                }
            }
        }
    }
}

private struct ObstacleView: View {
    let obstacle: Obstacle
    let size: CGSize

    var body: some View {
        Group {
            if obstacle.type == .wall {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: obstacle.width * size.width, height: 6)
            } else if obstacle.type == .enemy {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            } else if obstacle.type == .turret {
                ZStack {
                    Rectangle().fill(Color.red).frame(width: 10, height: 10)
                    Rectangle().fill(Color.black).frame(width: 4, height: 4)
                }
            }
        }
        .position(x: obstacle.x * size.width, y: obstacle.y * size.height)
    }
}

private struct HUD: View {
    let level: Int
    let progress: Double

    var body: some View {
        VStack {
            HStack {
                Text("LVL \(level)")
                    .font(.system(size: 9, weight: .black)) // 9pt floor
                    .accessibilityLabel("Current level \(level)")
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, design: .monospaced)) // 9pt floor
                    .accessibilityLabel("Mission progress \(Int(progress * 100)) percent")
            }
            .padding(5)
            Spacer()
        }
    }
}
