import Foundation
import Combine
import WatchKit

/// Drives the vent-crawl minigame.
///
/// Holds the normalized game state and delegates every tick to a
/// `VentCrawlEngine`. Reads shared mission context through the coordinator.
final class VentCrawlViewModel: ObservableObject {
    let coordinator: MissionCoordinator
    let clock: GameClock

    @Published var state: VentCrawlState = VentCrawlState(playerX: 0.5)

    private let engine: VentCrawlEngine
    private var cancellables = Set<AnyCancellable>()

    init(
        coordinator: MissionCoordinator,
        engine: VentCrawlEngine = GameVentCrawlEngine(),
        clock: GameClock = SystemGameClock()
    ) {
        self.coordinator = coordinator
        self.engine = engine
        self.clock = clock
        coordinator.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var session: GameSession { coordinator.session }

    func tick() {
        guard !coordinator.isPaused else { return }
        
        switch engine.step(state: &state, level: coordinator.level) {
        case .ongoing:
            break
        case .finished:
            coordinator.advance(to: .hacking)
            coordinator.hapticProvider.play(.directionUp)
        case .caught:
            coordinator.markCaught()
        }
    }
}
