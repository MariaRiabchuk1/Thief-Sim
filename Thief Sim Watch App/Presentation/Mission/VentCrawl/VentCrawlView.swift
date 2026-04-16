import SwiftUI
import Combine

/// Minigame: crawling through the vent.
struct VentCrawlView: View {
    @StateObject private var viewModel: VentCrawlViewModel

    init(coordinator: MissionCoordinator) {
        _viewModel = StateObject(wrappedValue: VentCrawlViewModel(coordinator: coordinator))
    }

    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black
            BackgroundGrid(distance: viewModel.ventDistance)

            ForEach(viewModel.bullets) { bullet in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 3, height: 3)
                    .position(x: CGFloat(bullet.x), y: CGFloat(bullet.y))
            }

            ForEach(viewModel.obstacles) { obs in
                ObstacleView(obstacle: obs)
            }

            PlayerFigureView(skinColor: viewModel.session.currentSkin.color, accessory: viewModel.session.currentAccessory)
                .position(x: CGFloat(viewModel.ventPosition), y: 120)

            HUD(level: viewModel.coordinator.level + 1, distance: Int(viewModel.ventDistance))
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .focusable()
        .digitalCrownRotation($viewModel.ventPosition, from: 15, through: 135, by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: false)
        .onReceive(tick) { _ in viewModel.tick() }
    }
}

private struct BackgroundGrid: View {
    let distance: Double
    var body: some View {
        VStack(spacing: 30) {
            ForEach(0..<6) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .offset(y: CGFloat((Int(distance * 20) % 30) + (i * 30)))
            }
        }
    }
}

private struct ObstacleView: View {
    let obstacle: Obstacle
    var body: some View {
        Group {
            if obstacle.type == .wall {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: CGFloat(obstacle.width), height: 6)
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
        .position(x: CGFloat(obstacle.x), y: CGFloat(obstacle.y))
    }
}

private struct HUD: View {
    let level: Int
    let distance: Int
    var body: some View {
        VStack {
            HStack {
                Text("LVL \(level)").font(.system(size: 8, weight: .black))
                Spacer()
                Text("\(distance)m").font(.system(size: 8, design: .monospaced))
            }
            .padding(5)
            Spacer()
        }
    }
}
