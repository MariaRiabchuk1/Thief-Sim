import SwiftUI

/// Reusable player character visualization.
struct PlayerFigureView: View {
    let skinColor: Color
    let accessory: Accessory?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(skinColor)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 6, height: 2)
                Rectangle()
                    .fill(skinColor)
                    .frame(width: 10, height: 10)
            }
            
            if let acc = accessory {
                Text(acc.icon)
                    .font(.system(size: 8))
                    .offset(x: acc.offset.x, y: acc.offset.y)
            }
        }
    }
}
