import SwiftUI

/// Root view that handles navigation between game states.
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    // Timers
    let fastTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let globalTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Group {
                switch viewModel.gameState {
                case .map:
                    MapView(viewModel: viewModel)
                case .shop:
                    ShopView(viewModel: viewModel)
                case .ventCrawl:
                    VentCrawlView(viewModel: viewModel)
                case .hacking:
                    HackingView(viewModel: viewModel)
                case .safeCracking:
                    SafeCrackingView(viewModel: viewModel)
                case .success:
                    SuccessView(viewModel: viewModel)
                case .caught:
                    CaughtView(viewModel: viewModel)
                }
            }
        }
        .onReceive(fastTimer) { _ in viewModel.handleFastTick() }
        .onReceive(globalTimer) { _ in viewModel.handleGlobalTick() }
        .alert(item: $viewModel.infoAlert) { item in
            Alert(
                title: Text(item.name),
                message: Text("\(item.description)\n\n\(item.helpText)"),
                dismissButton: .default(Text("ОК"))
            )
        }
    }
}
