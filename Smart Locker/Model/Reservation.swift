import Foundation
import FirebaseFirestore

struct Reservation: Identifiable, Codable {
    let id: String
    let userId: String
    let locationId: String
    let locationName: String
    let locationAddress: String
    let coordinates: GeoPoint
    let size: String
    let dimensions: String
    let basePrice: Double
    let dates: [Timestamp]
    let status: String
    let createdAt: Timestamp
    var confirmedAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case locationId
        case locationName
        case locationAddress
        case coordinates
        case size
        case dimensions
        case basePrice
        case dates
        case status
        case createdAt
        case confirmedAt
    }
} 