import Foundation

enum PlanTier: String, CaseIterable, Identifiable, Codable {
    case premium = "Premium"
    case standard = "Standard"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .premium:
            return "Our premium plan provides enhanced security features and insurance coverage."
        case .standard:
            return "Our standard plan offers reliable storage for travelers at an affordable price."
        }
    }
    
    var features: [String] {
        switch self {
        case .premium:
            return [
                "You can monitor the Smart Locker Shop instantly",
                "You will be alerted in case of suspicious movement or an attempt to open the locker",
                "Up to $500 insurance payment is made if your belongings are stolen"
            ]
        case .standard:
            return [
                "Access to digital lockers with QR code unlocking",
                "View nearby Smart Locker shops on the map and get directions",
                "Easy and reliable storage for travelers",
                "Does not include High Security or Insurance"
            ]
        }
    }
    
    var primaryColor: String {
        switch self {
        case .premium: return "premiumYellow"
        case .standard: return "standardBlue"
        }
    }
}

enum PlanDuration: String, CaseIterable, Identifiable, Codable {
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .hourly: return "Perfect for quick stops"
        case .daily: return "Ideal for day trips"
        case .weekly: return "Great for vacations"
        case .monthly: return "Best for extended travel"
        }
    }
    
    func getPrice(for tier: PlanTier) -> Double {
        switch (self, tier) {
        case (.hourly, .premium): return 3.5
        case (.hourly, .standard): return 2.0
        case (.daily, .premium): return 20.0
        case (.daily, .standard): return 15.0
        case (.weekly, .premium): return 65.0
        case (.weekly, .standard): return 50.0
        case (.monthly, .premium): return 180.0
        case (.monthly, .standard): return 150.0
        }
    }
    
    var multiplier: Int {
        switch self {
        case .hourly: return 1
        case .daily: return 24
        case .weekly: return 24 * 7
        case .monthly: return 24 * 30
        }
    }
}

struct Plan: Identifiable, Codable {
    var id: String
    var tier: PlanTier
    var duration: PlanDuration
    var numberOfHours: Int?
    var customPrice: Double?
    
    var price: Double {
        if duration == .hourly, let hours = numberOfHours {
            return tier.hourlyRate * Double(hours)
        }
        return duration.getPrice(for: tier)
    }
    
    var totalHours: Int {
        if duration == .hourly, let hours = numberOfHours {
            return hours
        }
        return duration.multiplier
    }
    
    init(tier: PlanTier, duration: PlanDuration, numberOfHours: Int? = nil, price: Double? = nil) {
        self.id = UUID().uuidString
        self.tier = tier
        self.duration = duration
        self.numberOfHours = numberOfHours
        self.customPrice = price
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tier
        case duration
        case numberOfHours
        case customPrice
    }
    
    static var defaultPlan: Plan {
        return Plan(tier: .standard, duration: .daily)
    }
} 