import SwiftUI

/// Minigame: hacking the alarm system.
struct HackingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            Text("СИГНАЛІЗАЦІЯ").font(.caption).foregroundColor(.red)
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .cornerRadius(10)
                Rectangle()
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 30, height: 20)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 26)
                    .offset(x: CGFloat(viewModel.hackPosition))
            }
            
            Button("ХАКНУТИ") { viewModel.performHack() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            
            if (viewModel.consumables["ЕМІ"] ?? 0) > 0 {
                Button("ЕМІ (-1)") { viewModel.useEMP() }
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}
