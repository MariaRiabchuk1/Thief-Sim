import SwiftUI
import Combine

/// Root view that switches screens based on the app router.
struct ContentView: View {
    @StateObject private var session: GameSession
    @StateObject private var router: AppRouter
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var shopViewModel: ShopViewModel
    
    @Environment(\.scenePhase) private var scenePhase

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
        
        // Initial check for recovery
        router.checkForRecovery()
    }

    var body: some View {
        ZStack {
            if router.pendingRecoverySnapshot != nil {
                RecoveryView(router: router, session: session)
            } else {
                mainContent
            }
        }
        .id(router.gameState)
        .onOpenURL { url in
            router.handleDeepLink(url)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .alert(item: $shopViewModel.infoAlert) { item in
            Alert(
                title: Text(item.name),
                message: Text("\(item.description)\n\n\(item.helpText)"),
                dismissButton: .default(Text("ОК"))
            )
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
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
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard let mission = router.activeMission else { return }
        
        switch phase {
        case .active:
            mission.isPaused = false
        case .inactive, .background:
            mission.isPaused = true
            mission.saveSnapshot()
        @unknown default:
            break
        }
    }
}

/// View shown when a mission can be recovered.
struct RecoveryView: View {
    @ObservedObject var router: AppRouter
    let session: GameSession
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("ЗНАЙДЕНО ПЕРЕРВАНУ МІСІЮ")
                .font(.system(size: 9, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("Бажаєте продовжити?")
                .font(.system(size: 8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 5) {
                Button("ПРОДОВЖИТИ") {
                    withAnimation {
                        router.recoverMission(session: session)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
                
                Button("СКАСУВАТИ") {
                    withAnimation {
                        router.abandonMission()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding()
    }
}
