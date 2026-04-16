import SwiftUI
import Combine

/// Root view that handles navigation between game states.
struct ContentView: View {
    @StateObject private var session: GameSession
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var shopViewModel: ShopViewModel

    let fastTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let globalTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init() {
        let session = GameSession()
        let gameVM = GameViewModel(session: session)
        let mapVM = MapViewModel(session: session)
        let shopVM = ShopViewModel(session: session)

        mapVM.onStartMission = { [weak gameVM] district, bribe in
            gameVM?.startMission(district: district, bribeActive: bribe)
        }
        mapVM.onOpenShop = { [weak gameVM] in gameVM?.openShop() }
        shopVM.onClose = { [weak gameVM] in gameVM?.closeShop() }

        _session = StateObject(wrappedValue: session)
        _gameViewModel = StateObject(wrappedValue: gameVM)
        _mapViewModel = StateObject(wrappedValue: mapVM)
        _shopViewModel = StateObject(wrappedValue: shopVM)
    }

    var body: some View {
        ZStack {
            Group {
                switch gameViewModel.gameState {
                case .map:
                    MapView(viewModel: mapViewModel)
                case .shop:
                    ShopView(viewModel: shopViewModel)
                case .ventCrawl:
                    VentCrawlView(viewModel: gameViewModel)
                case .hacking:
                    HackingView(viewModel: gameViewModel)
                case .safeCracking:
                    SafeCrackingView(viewModel: gameViewModel)
                case .success:
                    SuccessView(viewModel: gameViewModel)
                case .caught:
                    CaughtView(viewModel: gameViewModel)
                }
            }
        }
        .onReceive(fastTimer) { _ in gameViewModel.handleFastTick() }
        .onReceive(globalTimer) { _ in gameViewModel.handleGlobalTick() }
        .alert(item: $shopViewModel.infoAlert) { item in
            Alert(
                title: Text(item.name),
                message: Text("\(item.description)\n\n\(item.helpText)"),
                dismissButton: .default(Text("ОК"))
            )
        }
    }
}
