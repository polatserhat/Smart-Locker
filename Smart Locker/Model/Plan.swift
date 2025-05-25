import Foundation

enum PlanTier: String, CaseIterable, Identifiable, Codable {
    case premium = "Premium"
    case standard = "Standard"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .premium:
            return "Improved user experience with smart reminders, remote access, and priority support."
        case .standard:
            return "Basic secure storage with digital access."
        }
    }
    
    var features: [String] {
        switch self {
        case .premium:
            return [
                "Remote locker control",
                "Usage Time Reminders",
                "Insurance coverage",
                "Priority customer support"
            ]
        case .standard:
            return [
                "Digital QR code access",
                "Basic locker security",
                "24/7 customer support",
                "No insurance coverage"
            ]
        }
    }
    
    // Hourly rates
    var hourlyRate: Double {
        switch self {
        case .premium: return 4.99
        case .standard: return 2.99
        }
    }
    
    // 24-hour discounted rates (approximately 20% off hourly rate for 24 hours)
    var dailyRate: Double {
        switch self {
        case .premium: return 89.99  // Instead of 119.76 (24 * 4.99)
        case .standard: return 49.99  // Instead of 71.76 (24 * 2.99)
        }
    }
}

// For our simplified rental system
enum PlanDuration: String, CaseIterable, Identifiable, Codable {
    case hourly = "Hourly"
    case daily = "Daily"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .hourly:
            return "Pay only for the time you use"
        case .daily:
            return "24-hour access with discount"
        }
    }
    
    func getPrice(for tier: PlanTier) -> Double {
        switch self {
        case .hourly:
            return tier.hourlyRate
        case .daily:
            return tier.dailyRate
        }
    }
}

// For direct rentals, we only use hourly
enum RentalDuration: String, Codable {
    case hourly = "Hourly"
    
    var description: String {
        return "Pay only for the time you use"
    }
}

struct Plan: Identifiable, Codable {
    var id: String
    var tier: PlanTier
    var duration: PlanDuration
    var startTime: Date
    var endTime: Date?
    var customPrice: Double?
    var totalHours: Int?
    
    // Calculate price based on duration
    var price: Double {
        if let customPrice = customPrice {
            return customPrice
        }
        
        if let hours = totalHours, hours > 0 {
            // If rental duration is 24 hours or more, apply daily rate
            if hours >= 24 {
                let days = Double(hours) / 24.0
                return ceil(days) * tier.dailyRate
            }
            
            // Otherwise charge hourly
            return Double(hours) * tier.hourlyRate
        }
        
        guard let end = endTime else {
            return tier.hourlyRate // Default to 1 hour if no end time
        }
        
        let hours = Calendar.current.dateComponents([.hour], from: startTime, to: end).hour ?? 0
        
        // If rental duration is 24 hours or more, apply daily rate
        if hours >= 24 {
            let days = Double(hours) / 24.0
            return ceil(days) * tier.dailyRate
        }
        
        // Otherwise charge hourly
        return Double(max(1, hours)) * tier.hourlyRate
    }
    
    init(tier: PlanTier, duration: PlanDuration = .hourly, startTime: Date = Date(), endTime: Date? = nil, customPrice: Double? = nil, totalHours: Int? = nil) {
        self.id = UUID().uuidString
        self.tier = tier
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.customPrice = customPrice
        self.totalHours = totalHours
    }
} 
