import SwiftUI

struct SuccessScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        let reward = manager.isTreasureLevel ? manager.currentDistrict.reward * 2 : manager.currentDistrict.reward
        return VStack(spacing: 10) {
            Image(systemName: manager.isTreasureLevel ? "sparkles" : "banknote.fill").font(.largeTitle).foregroundColor(manager.isTreasureLevel ? .yellow : .green)
            Text(manager.isTreasureLevel ? "ЗОЛОТИЙ КУШ!" : "УСПІХ!").font(.headline)
            Text("+ $\(reward)").foregroundColor(.green).bold()
            Button("ВТІКТИ") { 
                manager.totalMoney += reward
                manager.totalEarnings += reward
                manager.gameState = .map 
            }.buttonStyle(.borderedProminent).tint(.green)
        }
    }
}

struct CaughtScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.raised.slash.fill").font(.largeTitle).foregroundColor(.red)
            Text("ВАС СПІЙМАНО!").font(.headline)
            Button("ЗДАТИСЯ") { 
                manager.totalMoney /= 2
                manager.gameState = .map 
            }.buttonStyle(.borderedProminent).tint(.red)
        }
    }
}
