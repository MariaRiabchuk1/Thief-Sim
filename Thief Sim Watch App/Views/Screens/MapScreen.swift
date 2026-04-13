import SwiftUI

struct MapScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                VStack(alignment: .leading) {
                    Text("$\(manager.totalMoney)").foregroundColor(.yellow).bold()
                    Text(manager.playerRank).font(.system(size: 8)).foregroundColor(.blue).italic()
                }
                Spacer()
                Button(action: { manager.gameState = .shop }) {
                    Image(systemName: "cart.fill").foregroundColor(.white)
                }
                .buttonStyle(.plain).padding(5).background(Color.blue.opacity(0.3)).cornerRadius(5)
            }.padding(.horizontal)
            
            TabView(selection: $manager.selectedDistrictIndex) {
                ForEach(0..<GameManager.districtsData.count, id: \.self) { i in
                    let district = GameManager.districtsData[i]
                    VStack {
                        Text(district.name).font(.headline)
                        Text("Куш: $\(district.reward)").foregroundColor(.green).font(.caption)
                        HStack {
                            if district.timeLimit != nil { Image(systemName: "timer").foregroundColor(.orange) }
                            if district.hasPatrol { Image(systemName: "figure.walk").foregroundColor(.red).padding(.leading, 5) }
                        }.font(.caption2)
                        Button("ПОЧАТИ") { manager.startMission() }.buttonStyle(.borderedProminent).tint(.red)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}
