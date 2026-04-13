import SwiftUI

struct VentScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack {
            Text("ВЕНТИЛЯЦІЯ: \(Int(manager.ventDistance))м").font(.system(size: 10, design: .monospaced))
            ZStack {
                Color.black.overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                ForEach(manager.obstacles) { obs in
                    Rectangle().fill(Color.red).frame(width: 40, height: 4).position(x: obs.x, y: obs.y)
                }
                Text("🕵️").font(.system(size: 20)).position(x: manager.ventPosition, y: 120)
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .focusable()
        .digitalCrownRotation($manager.ventPosition, from: 20, through: 120, by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: false)
    }
}
