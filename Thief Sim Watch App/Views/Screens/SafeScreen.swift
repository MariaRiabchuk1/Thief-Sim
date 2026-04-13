import SwiftUI

struct SafeScreen: View {
    @ObservedObject var manager: GameManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if manager.timeRemaining > 0 { Text("\(manager.timeRemaining)с").font(.system(size: 11, weight: .bold)).foregroundColor(manager.timeRemaining < 10 ? .red : .orange) }
                if (manager.consumables["Дим. шашка"] ?? 0) > 0 {
                    Button(action: {
                        manager.consumables["Дим. шашка"]! -= 1
                        withAnimation { manager.detectionLevel = 0.0 }
                        WKInterfaceDevice.current().play(.success)
                    }) { HStack(spacing: 2) { Image(systemName: "wind"); Text("\(manager.consumables["Дим. шашка", default: 0])").font(.system(size: 8)) } }.buttonStyle(.plain).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "heart.fill").foregroundColor(.red).scaleEffect(1.0 + manager.detectionLevel * 0.4)
                Spacer()
                Image(systemName: manager.isPatrolActive ? "eye.trianglebadge.exclamationmark.fill" : "eye.fill").foregroundColor(manager.isPatrolActive ? .red : (manager.detectionLevel > 0.7 ? .orange : .blue.opacity(0.5)))
            }.padding(.horizontal, 10).padding(.top, 5)
            
            Spacer()
            ZStack {
                if manager.isLockStuck {
                    VStack { Text("ЗАЇЛО!").font(.system(size: 14, weight: .black)).foregroundColor(.orange); Text("ТАПАЙ ШВИДКО").font(.system(size: 8)) }
                } else {
                    dialView
                }
            }
            .contentShape(Circle()).onTapGesture { 
                if manager.isLockStuck { 
                    manager.stuckProgress += 1
                    WKInterfaceDevice.current().play(.click)
                    if manager.stuckProgress >= 5 {
                        manager.isLockStuck = false
                        WKInterfaceDevice.current().play(.success)
                    }
                } 
            }
            
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
        }.frame(width: 85, height: 85).offset(x: manager.isPatrolActive ? 0 : CGFloat.random(in: -manager.detectionLevel*5...manager.detectionLevel*5))
    }
}
