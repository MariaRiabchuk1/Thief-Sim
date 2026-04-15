import SwiftUI
import WatchKit

// MARK: - Screens
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
                Button(action: { manager.gameState = .shop }) { Image(systemName: "cart.fill").foregroundColor(.white) }
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
                    }.tag(i)
                }
            }.tabViewStyle(PageTabViewStyle())
        }
    }
}

struct ShopScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("$\(manager.totalMoney)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.yellow)
                Spacer()
                Button(action: { manager.gameState = .map }) { Text("НАЗАД").font(.system(size: 9, weight: .medium)).foregroundColor(.blue) }.buttonStyle(.plain)
            }.padding(.horizontal, 12).padding(.top, 5).padding(.bottom, 2)
            List {
                Section(header: Text("АКСЕСУАРИ").font(.system(size: 8))) {
                    ForEach(GameManager.accessoriesData) { acc in
                        HStack {
                            Text(acc.icon).font(.system(size: 14))
                            VStack(alignment: .leading) { Text(acc.name).font(.system(size: 10, weight: .bold)); Text("$\(acc.price)").font(.system(size: 8)).foregroundColor(.yellow) }
                            Spacer()
                            Button(action: { manager.buyAccessory(acc) }) {
                                if manager.ownedAccessories.contains(acc.name) { Image(systemName: manager.currentAccessoryName == acc.name ? "checkmark.circle.fill" : "circle").foregroundColor(.green) }
                                else { Text("КУПИТИ").font(.system(size: 7, weight: .bold)).padding(4).background(manager.totalMoney >= acc.price ? Color.blue : Color.gray).cornerRadius(4) }
                            }.disabled(manager.currentAccessoryName == acc.name || (manager.totalMoney < acc.price && !manager.ownedAccessories.contains(acc.name)))
                        }
                    }
                }
                Section(header: Text("ГАДЖЕТИ").font(.system(size: 8))) {
                    ForEach(GameManager.shopItemsData) { item in
                        HStack {
                            VStack(alignment: .leading) { Text(item.name).font(.system(size: 10, weight: .bold)); Text("$\(item.price)").font(.system(size: 8)).foregroundColor(.yellow) }
                            Spacer()
                            Button(action: { manager.infoAlert = item }) { Image(systemName: "info.circle").foregroundColor(.blue) }.buttonStyle(.plain).padding(.trailing, 5)
                            Button(action: { manager.buyItem(item) }) { Text(item.isConsumable ? "+\(manager.consumables[item.name, default: 0])" : "КУПИТИ").font(.system(size: 7, weight: .bold)).padding(4).background(manager.totalMoney >= item.price ? Color.blue : Color.gray).cornerRadius(4) }.disabled(!item.isConsumable && manager.ownedUpgrades.contains(item.name) || manager.totalMoney < item.price)
                        }
                    }
                }
            }
        }
    }
}

struct VentScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 30) { ForEach(0..<6) { i in Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1).offset(y: CGFloat((Int(manager.ventDistance * 20) % 30) + (i * 30))) } }
            ForEach(manager.bullets) { bullet in Rectangle().fill(Color.yellow).frame(width: 3, height: 3).position(x: CGFloat(bullet.x), y: CGFloat(bullet.y)) }
            ForEach(manager.obstacles) { obs in
                if obs.type == .wall { Rectangle().fill(Color.white.opacity(0.8)).frame(width: CGFloat(obs.width), height: 6).position(x: CGFloat(obs.x), y: CGFloat(obs.y)) }
                else if obs.type == .enemy { Rectangle().fill(Color.red).frame(width: 8, height: 8).position(x: CGFloat(obs.x), y: CGFloat(obs.y)) }
                else if obs.type == .turret { ZStack { Rectangle().fill(Color.red).frame(width: 10, height: 10); Rectangle().fill(Color.black).frame(width: 4, height: 4) }.position(x: CGFloat(obs.x), y: CGFloat(obs.y)) }
            }
            PlayerFigure(manager: manager).position(x: CGFloat(manager.ventPosition), y: 120)
            VStack { HStack { Text("LEVEL \(manager.currentDistrictLevel + 1)").font(.system(size: 8, weight: .black)); Spacer(); Text("\(Int(manager.ventDistance))m").font(.system(size: 8, design: .monospaced)) }.padding(5); Spacer() }
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .focusable()
        .digitalCrownRotation($manager.ventPosition, from: 15, through: 135, by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: false)
    }
}

struct HackingScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        VStack(spacing: 15) {
            Text("СИГНАЛІЗАЦІЯ").font(.caption).foregroundColor(.red)
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 120, height: 20).cornerRadius(10)
                Rectangle().fill(Color.green.opacity(0.5)).frame(width: 30, height: 20)
                Rectangle().fill(Color.white).frame(width: 4, height: 26).offset(x: CGFloat(manager.hackPosition))
            }
            Button("ХАКНУТИ") { 
                if abs(manager.hackPosition) < 15 { WKInterfaceDevice.current().play(.success); manager.gameState = .safeCracking }
                else { WKInterfaceDevice.current().play(.failure); manager.detectionLevel += 0.3; if manager.detectionLevel >= 1.0 { manager.gameState = .caught } }
            }.buttonStyle(.borderedProminent).tint(.blue)
            if (manager.consumables["ЕМІ"] ?? 0) > 0 { Button("ЕМІ (-1)") { manager.consumables["ЕМІ"]! -= 1; manager.empActive = true; manager.gameState = .safeCracking; WKInterfaceDevice.current().play(.success) }.font(.caption2).foregroundColor(.orange) }
        }
    }
}

struct SafeScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if manager.timeRemaining > 0 { Text("\(manager.timeRemaining)с").font(.system(size: 11, weight: .bold)).foregroundColor(manager.timeRemaining < 10 ? .red : .orange) }
                if (manager.consumables["Дим. шашка"] ?? 0) > 0 {
                    Button(action: { manager.consumables["Дим. шашка"]! -= 1; withAnimation { manager.detectionLevel = 0.0 }; WKInterfaceDevice.current().play(.success) }) { HStack(spacing: 2) { Image(systemName: "wind"); Text("\(manager.consumables["Дим. шашка", default: 0])").font(.system(size: 8)) } }.buttonStyle(.plain).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "heart.fill").foregroundColor(.red).scaleEffect(1.0 + manager.detectionLevel * 0.4)
                Spacer()
                Image(systemName: manager.isPatrolActive ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill").foregroundColor(manager.isPatrolActive ? .red : (manager.detectionLevel > 0.7 ? .orange : .blue.opacity(0.5)))
            }.padding(.horizontal, 10).padding(.top, 5)
            Spacer()
            ZStack {
                if manager.isLockStuck { VStack { Text("ЗАЇЛО!").font(.system(size: 14, weight: .black)).foregroundColor(.orange); Text("ТАПАЙ ШВИДКО").font(.system(size: 8)) } }
                else { dialView }
            }
            .contentShape(Circle()).onTapGesture { if manager.isLockStuck { manager.stuckProgress += 1; WKInterfaceDevice.current().play(.click); if manager.stuckProgress >= 5 { manager.isLockStuck = false; manager.stuckProgress = 0; WKInterfaceDevice.current().play(.success) } } }
            Spacer()
            VStack(spacing: 3) {
                HStack(spacing: 4) { ForEach(0..<manager.currentDistrict.codeLength, id: \.self) { i in Circle().fill(i < manager.currentStep ? Color.green : Color.gray).frame(width: 5, height: 5) } }
                if !manager.isLockStuck { Button("ЗЛАМАТИ") { manager.tryCrackSafe() }.buttonStyle(.bordered).tint(.blue).controlSize(.small) }
            }.padding(.bottom, 5)
        }
        .focusable()
        .digitalCrownRotation($manager.crownValue, from: 0, through: 100, by: 0.5, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: false)
        .onChange(of: manager.crownValue) { oldValue, newValue in manager.handleSafeInput(newValue) }
    }
    var dialView: some View {
        ZStack {
            if manager.isPatrolActive { Circle().fill(Color.red.opacity(0.2)).frame(width: 95, height: 95).blur(radius: 5) }
            let boost = manager.ownedUpgrades.contains("Стетоскоп") ? 1.5 : 1.0
            Circle().stroke(manager.isTreasureLevel ? Color.yellow : Color.blue, lineWidth: 2).scaleEffect(1.0 + manager.resonanceAlpha * 0.3 * boost).opacity(manager.resonanceAlpha)
            Circle().fill(RadialGradient(colors: [.gray.opacity(0.2), .black], center: .center, startRadius: 0, endRadius: 50))
            Circle().fill(LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom)).frame(width: 65, height: 65).rotationEffect(.degrees(manager.crownValue * 3.6))
            Rectangle().fill(manager.resonanceAlpha > 0.8 ? Color.green : Color.red).frame(width: 3, height: 8).offset(y: -28).rotationEffect(.degrees(manager.crownValue * 3.6))
        }.frame(width: 85, height: 85).offset(x: manager.isPatrolActive ? 0 : CGFloat.random(in: CGFloat(-manager.detectionLevel*5)...CGFloat(manager.detectionLevel*5)))
    }
}

// MARK: - Components
struct PlayerFigure: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(manager.currentSkin.color).frame(width: 6, height: 6)
                Rectangle().fill(Color.black).frame(width: 6, height: 2)
                Rectangle().fill(manager.currentSkin.color).frame(width: 10, height: 10)
            }
            if let acc = manager.currentAccessory { Text(acc.icon).font(.system(size: 8)).offset(x: acc.offset.x, y: acc.offset.y) }
        }
    }
}

struct SuccessScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        let reward = manager.isTreasureLevel ? manager.currentDistrict.reward * 2 : manager.currentDistrict.reward
        return VStack(spacing: 10) {
            Image(systemName: manager.isTreasureLevel ? "sparkles" : "banknote.fill").font(.largeTitle).foregroundColor(manager.isTreasureLevel ? .yellow : .green)
            Text(manager.isTreasureLevel ? "ЗОЛОТИЙ КУШ!" : "УСПІХ!").font(.headline)
            Text("+ $\(reward)").foregroundColor(.green).bold()
            Button("ВТІКТИ") { manager.totalMoney += reward; manager.totalEarnings += reward; manager.gameState = .map }.buttonStyle(.borderedProminent).tint(.green)
        }
    }
}

struct CaughtScreen: View {
    @ObservedObject var manager: GameManager
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.raised.slash.fill").font(.largeTitle).foregroundColor(.red)
            Text("ВАС СПІЙМАНО!").font(.headline)
            Button("ЗДАТИСЯ") { manager.totalMoney /= 2; manager.gameState = .map }.buttonStyle(.borderedProminent).tint(.red)
        }
    }
}
