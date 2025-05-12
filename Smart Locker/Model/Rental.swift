import Foundation
import FirebaseFirestore

struct Rental: Identifiable {
    let id: String
    let userId: String
    let lockerId: String
    let locationName: String
    let size: String
    let startDate: Date
    let endDate: Date
    let status: String
    
    init(snapshot: DocumentSnapshot) {
        let data = snapshot.data() ?? [:]
        self.id = snapshot.documentID
        self.userId = data["userId"] as? String ?? ""
        self.lockerId = data["lockerId"] as? String ?? ""
        self.locationName = data["locationName"] as? String ?? ""
        self.size = data["size"] as? String ?? ""
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        self.status = data["status"] as? String ?? ""
    }
    
    // Direct initializer for previews and testing
    init(id: String, userId: String, lockerId: String, locationName: String, size: String, startDate: Date, endDate: Date, status: String) {
        self.id = id
        self.userId = userId
        self.lockerId = lockerId
        self.locationName = locationName
        self.size = size
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
    }
} 