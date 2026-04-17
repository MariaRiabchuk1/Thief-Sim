import Testing
import Foundation
@testable import Thief_Sim_Watch_App

@Suite("EconomyService")
struct EconomyServiceTests {
    let service = GameEconomyService()

    @Test("Upkeep scales linearly based on unlocked districts")
    func upkeepCalculation() {
        #expect(service.getUpkeepCost(unlockedDistrictsCount: 0) == 0)
        #expect(service.getUpkeepCost(unlockedDistrictsCount: 1) == 50)
        #expect(service.getUpkeepCost(unlockedDistrictsCount: 3) == 150)
    }

    @Test("Bribe price is exactly 25% of reward")
    func bribePricing() {
        #expect(service.calculateBribePrice(reward: 200) == 50)
        #expect(service.calculateBribePrice(reward: 800) == 200)
        #expect(service.calculateBribePrice(reward: 3000) == 750)
    }

    @Test("canUnlockDistrict validates against current money")
    func districtUnlocking() {
        let district = District(id: .center, name: "Center", reward: 800, codeLength: 2, safeTolerance: 2.0, hackSpeed: 4.0, hasPatrol: true, timeLimit: 45, unlockPrice: 2000)
        
        #expect(service.canUnlockDistrict(totalMoney: 1999, district: district) == false)
        #expect(service.canUnlockDistrict(totalMoney: 2000, district: district) == true)
        #expect(service.canUnlockDistrict(totalMoney: 5000, district: district) == true)
    }

    @Test("Player rank transitions at correct thresholds")
    func rankThresholds() {
        // Novice < 1000
        #expect(service.getPlayerRank(totalEarnings: 0) == "Новачок (Підвал)")
        #expect(service.getPlayerRank(totalEarnings: 999) == "Новачок (Підвал)")
        
        // Burglar 1000...4999
        #expect(service.getPlayerRank(totalEarnings: 1000) == "Зломщик (Гараж)")
        #expect(service.getPlayerRank(totalEarnings: 4999) == "Зломщик (Гараж)")
        
        // Master 5000...19999
        #expect(service.getPlayerRank(totalEarnings: 5000) == "Майстер (Сховище)")
        #expect(service.getPlayerRank(totalEarnings: 19999) == "Майстер (Сховище)")
        
        // Ghost >= 20000
        #expect(service.getPlayerRank(totalEarnings: 20000) == "Привид (Пентхаус)")
        #expect(service.getPlayerRank(totalEarnings: 100000) == "Привид (Пентхаус)")
    }
    
    @Test("canBuyItem validates price against money")
    func buyItemValidation() {
        #expect(service.canBuyItem(totalMoney: 50, price: 100) == false)
        #expect(service.canBuyItem(totalMoney: 100, price: 100) == true)
    }
}
