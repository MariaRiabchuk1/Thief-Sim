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
                    .accessibilityLabel("Balance \(money) dollars")
                Text(rank)
                    .font(.system(size: 9)) // 9pt floor
                    .foregroundColor(.blue)
                    .italic()
                    .accessibilityLabel("Rank \(rank)")
            }
            Spacer()
            Button(action: onShopTap) {
                Image(systemName: "cart.fill")
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Shop")
            .padding(5)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(5)
        }
        .padding(.horizontal)
    }
}
