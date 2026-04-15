import SwiftUI

/// HUD display for money and rank.
struct HUDView: View {
    let money: Int
    let rank: String
    let onShopTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("$\(money)")
                    .foregroundColor(.yellow)
                    .bold()
                Text(rank)
                    .font(.system(size: 7))
                    .foregroundColor(.blue)
                    .italic()
            }
            Spacer()
            Button(action: onShopTap) {
                Image(systemName: "cart.fill")
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .padding(5)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(5)
        }
        .padding(.horizontal)
    }
}
