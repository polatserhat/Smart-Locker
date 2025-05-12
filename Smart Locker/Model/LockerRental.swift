import Foundation

enum RentalType: String, Codable {
    case instant
    case reservation
    
    var title: String {
        switch self {
        case .instant:
            return "Direct Rent"
        case .reservation:
            return "Reservation"
        }
    }
    
    var description: String {
        switch self {
        case .instant:
            return "Rent a locker right now"
        case .reservation:
            return "Book a locker for later"
        }
    }
}

enum LockerSize: String, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var dimensions: String {
        switch self {
        case .small: return "30 x 30 x 45 cm"
        case .medium: return "45 x 45 x 60 cm"
        case .large: return "60 x 60 x 90 cm"
        }
    }
    
    var basePrice: Double {
        switch self {
        case .small: return 0.10
        case .medium: return 0.15
        case .large: return 0.20
        }
    }
}

struct LockerRental: Identifiable, Codable {
    let id: String
    let shopName: String
    let size: LockerSize
    let rentalType: RentalType
    let reservationDate: Date?
    var startTime: Date?
    var endTime: Date?
    var status: RentalStatus = .pending
    var totalPrice: Double?
    var plan: Plan?
    
    enum RentalStatus: String, Codable {
        case pending = "Pending"
        case active = "Active"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopName
        case size
        case rentalType
        case reservationDate
        case startTime
        case endTime
        case status
        case totalPrice
        case plan
    }
    
    // Custom initializer to fix Codable issue with default values
    init(id: String, shopName: String, size: LockerSize, rentalType: RentalType, 
         reservationDate: Date? = nil, startTime: Date? = nil, endTime: Date? = nil, 
         status: RentalStatus = .pending, totalPrice: Double? = nil, plan: Plan? = nil) {
        self.id = id
        self.shopName = shopName
        self.size = size
        self.rentalType = rentalType
        self.reservationDate = reservationDate
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.totalPrice = totalPrice
        self.plan = plan
    }
    
    var isRefundable: Bool {
        return rentalType == .reservation
    }
}

struct PaymentMethod: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var isSelected: Bool
}

struct PaymentDetails {
    var cardholderName: String = ""
    var cardNumber: String = ""
    var expiryDate: String = ""
    var cvv: String = ""
    var billingAddress: String = ""
} 