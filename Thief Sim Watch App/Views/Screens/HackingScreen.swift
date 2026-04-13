import SwiftUI
import WatchKit

struct HackingScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("СИГНАЛІЗАЦІЯ").font(.caption).foregroundColor(.red)
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 120, height: 20).cornerRadius(10)
                Rectangle().fill(Color.green.opacity(0.5)).frame(width: 30, height: 20)
                Rectangle().fill(Color.white).frame(width: 4, height: 26).offset(x: manager.hackPosition)
            }
            Button("ХАКНУТИ") { 
                if abs(manager.hackPosition) < 15 {
                    WKInterfaceDevice.current().play(.success)
                    manager.gameState = .safeCracking
                } else {
                    WKInterfaceDevice.current().play(.failure)
                    manager.detectionLevel += 0.3
                    if manager.detectionLevel >= 1.0 { manager.gameState = .caught }
                }
            }.buttonStyle(.borderedProminent).tint(.blue)
            
            if (manager.consumables["ЕМІ"] ?? 0) > 0 {
                Button("ЕМІ (-1)") {
                    manager.consumables["ЕМІ"]! -= 1
                    manager.empActive = true
                    manager.gameState = .safeCracking
                    WKInterfaceDevice.current().play(.success)
                }.font(.caption2).foregroundColor(.orange)
            }
        }
    }
}
