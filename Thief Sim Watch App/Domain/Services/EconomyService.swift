import Foundation

/// Business logic for game economy and progression.
protocol EconomyService {
    func canUnlockDistrict(totalMoney: Int, district: District) -> Bool
    func canBuyItem(totalMoney: Int, price: Int) -> Bool
    func getUpkeepCost(unlockedDistrictsCount: Int) -> Int
    func calculateBribePrice(reward: Int) -> Int
    func calculateBailFee(reward: Int) -> Int
    func getPlayerRank(totalEarnings: Int) -> String
}

class GameEconomyService: EconomyService {
    func canUnlockDistrict(totalMoney: Int, district: District) -> Bool {
        totalMoney >= district.unlockPrice
    }
    
    func canBuyItem(totalMoney: Int, price: Int) -> Bool {
        totalMoney >= price
    }
    
    func getUpkeepCost(unlockedDistrictsCount: Int) -> Int {
        unlockedDistrictsCount * 50
    }
    
    func calculateBribePrice(reward: Int) -> Int {
        reward / 4
    }
    
    func calculateBailFee(reward: Int) -> Int {
        reward / 8
    }
    
    func getPlayerRank(totalEarnings: Int) -> String {
        if totalEarnings < 1000 { return "Новачок (Підвал)" }
        if totalEarnings < 5000 { return "Зломщик (Гараж)" }
        if totalEarnings < 20000 { return "Майстер (Сховище)" }
        return "Привид (Пентхаус)"
    }
}
