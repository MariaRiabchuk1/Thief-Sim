import SwiftUI
import Combine

/// Root view that switches screens based on the app router.
///
/// Creates the session and non-mission view models once, wires navigation
/// closures, and hands each screen its own view model. Mission-phase views
/// build their own view models around the active `MissionCoordinator` and
/// run their own timers.
struct ContentView: View {
    @StateObject private var session: GameSession
    @StateObject private var router: AppRouter
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var shopViewModel: ShopViewModel

    init() {
        let session = GameSession()
        let router = AppRouter()
        let mapVM = MapViewModel(session: session)
        let shopVM = ShopViewModel(session: session)

        mapVM.onStartMission = { [weak session, weak router] district, bribe in
            guard let session, let router else { return }
            let coordinator = MissionCoordinator(
                session: session,
                router: router,
                district: district,
                bribeActive: bribe
            )
            router.activeMission = coordinator
            coordinator.start()
        }
        mapVM.onOpenShop = { [weak router] in router?.gameState = .shop }
        shopVM.onClose = { [weak router] in router?.gameState = .map }
        
        router.onDeepLinkDistrict = { [weak mapVM] districtId in
            mapVM?.selectDistrict(districtId)
        }

        _session = StateObject(wrappedValue: session)
        _router = StateObject(wrappedValue: router)
        _mapViewModel = StateObject(wrappedValue: mapVM)
        _shopViewModel = StateObject(wrappedValue: shopVM)
    }

    var body: some View {
        ZStack {
            switch router.gameState {
            case .map:
                MapView(viewModel: mapViewModel)
            case .shop:
                ShopView(viewModel: shopViewModel)
            case .ventCrawl:
                if let mission = router.activeMission {
                    VentCrawlView(coordinator: mission)
                }
            case .hacking:
                if let mission = router.activeMission {
                    HackingView(coordinator: mission)
                }
            case .safeCracking:
                if let mission = router.activeMission {
                    SafeCrackingView(coordinator: mission)
                }
            case .success:
                if let mission = router.activeMission {
                    SuccessView(coordinator: mission)
                }
            case .caught:
                if let mission = router.activeMission {
                    CaughtView(coordinator: mission)
                }
            }
        }
        .id(router.gameState)
        .onOpenURL { url in
            router.handleDeepLink(url)
        }
        .alert(item: $shopViewModel.infoAlert) { item in
            Alert(
                title: Text(item.name),
                message: Text("\(item.description)\n\n\(item.helpText)"),
                dismissButton: .default(Text("ОК"))
            )
        }
    }
}
