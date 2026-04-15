import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var manager = GameManager()
    
    private let globalTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let fastTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            switch manager.gameState {
            case .map: MapScreen(manager: manager)
            case .shop: ShopScreen(manager: manager)
            case .ventCrawl: VentScreen(manager: manager)
            case .hacking: HackingScreen(manager: manager)
            case .safeCracking: SafeScreen(manager: manager)
            case .success: SuccessScreen(manager: manager)
            case .caught: CaughtScreen(manager: manager)
            }
        }
        .onReceive(globalTimer) { _ in manager.handleGlobalTick() }
        .onReceive(fastTimer) { _ in manager.handleFastTick() }
        .alert(item: $manager.infoAlert) { item in
            Alert(title: Text(item.name), message: Text(item.helpText), dismissButton: .default(Text("Зрозумів")))
        }
    }
}

#Preview {
    ContentView()
}
