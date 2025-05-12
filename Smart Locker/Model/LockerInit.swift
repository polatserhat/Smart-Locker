import Foundation
import FirebaseFirestore

class LegacyLockerInitializer {
    static let shared = LegacyLockerInitializer()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Simple function to create available lockers
    func initializeLockers() {
        print("Checking if lockers need to be initialized...")
        
        // Check if we already have lockers
        db.collection("lockers").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking lockers: \(error.localizedDescription)")
                return
            }
            
            // If we already have lockers, don't create new ones
            if let documents = snapshot?.documents, !documents.isEmpty {
                print("Lockers already exist (\(documents.count) lockers). No need to initialize.")
                return
            }
            
            print("No lockers found. Creating 100 lockers...")
            self.createLockers()
        }
    }
    
    private func createLockers() {
        // Create 100 lockers (50 small, 30 medium, 20 large)
        let sizes = [
            ("Small", 50, "30 x 30 x 45 cm"),
            ("Medium", 30, "45 x 45 x 60 cm"),
            ("Large", 20, "60 x 60 x 90 cm")
        ]
        
        let locations = LockerLocation.sampleLocations
        
        var batch = db.batch()
        var lockerCount = 0
        
        for (size, count, dimensions) in sizes {
            for i in 0..<count {
                // Distribute evenly across locations
                let location = locations[i % locations.count]
                
                let lockerId = "locker_\(String(format: "%03d", lockerCount + 1))"
                let lockerRef = db.collection("lockers").document(lockerId)
                
                let lockerData: [String: Any] = [
                    "id": lockerId,
                    "number": String(format: "%03d", lockerCount + 1),
                    "size": size,
                    "status": "available",
                    "dimensions": dimensions,
                    "locationId": location.id.uuidString,
                    "locationName": location.name,
                    "locationAddress": location.address,
                    "createdAt": Timestamp(date: Date())
                ]
                
                batch.setData(lockerData, forDocument: lockerRef)
                lockerCount += 1
                
                // Commit every 500 operations (Firestore limit)
                if lockerCount % 500 == 0 {
                    let currentBatch = batch
                    batch = db.batch()
                    
                    currentBatch.commit { error in
                        if let error = error {
                            print("Error creating lockers batch: \(error)")
                        }
                    }
                }
            }
        }
        
        // Commit any remaining operations
        batch.commit { error in
            if let error = error {
                print("Error creating lockers: \(error)")
            } else {
                print("Successfully created 100 lockers")
                
                // Create statistics document if it doesn't exist
                let statsRef = self.db.collection("statistics").document("system_stats")
                
                let statsData: [String: Any] = [
                    "locker_stats": [
                        "total": 100,
                        "available": 100,
                        "occupied": 0,
                        "reserved": 0,
                        "maintenance": 0,
                        "distribution": [
                            "Small": 50,
                            "Medium": 30,
                            "Large": 20
                        ]
                    ],
                    "last_updated": Timestamp(date: Date())
                ]
                
                statsRef.setData(statsData, merge: true) { error in
                    if let error = error {
                        print("Error setting statistics: \(error)")
                    } else {
                        print("Statistics initialized")
                    }
                }
            }
        }
    }
} 