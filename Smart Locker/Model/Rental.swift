import Foundation
import FirebaseFirestore

struct Rental: Identifiable, Codable {
    let id: String
    let userId: String
    let locationId: String
    let locationName: String
    let locationAddress: String
    let coordinates: GeoPoint
    let size: String
    let dimensions: String
    let startDate: Timestamp
    let endDate: Timestamp
    let totalPrice: Double
    let status: String
    let createdAt: Timestamp
    var updatedAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case locationId
        case locationName
        case locationAddress
        case coordinates
        case size
        case dimensions
        case startDate
        case endDate
        case totalPrice
        case status
        case createdAt
        case updatedAt
    }
} 