import Foundation
import FirebaseFirestore

struct LockerInitializer {
    static let locations = [
        (
            id: "A001",
            name: "Smart Locker Shop - A-001",
            address: "123 Market St, San Francisco, CA 94105",
            coordinates: ["latitude": 37.7749, "longitude": -122.4194]
        ),
        (
            id: "B001",
            name: "Smart Locker Shop - B-001",
            address: "456 Mission St, San Francisco, CA 94105",
            coordinates: ["latitude": 37.7847, "longitude": -122.4089]
        ),
        (
            id: "C001",
            name: "Smart Locker Shop - C-001",
            address: "789 Howard St, San Francisco, CA 94103",
            coordinates: ["latitude": 37.7697, "longitude": -122.4269]
        ),
        (
            id: "D001",
            name: "Smart Locker Shop - D-001",
            address: "101 California St, San Francisco, CA 94111",
            coordinates: ["latitude": 37.7879, "longitude": -122.4074]
        ),
        (
            id: "E001",
            name: "Smart Locker Shop - E-001",
            address: "333 Post St, San Francisco, CA 94108",
            coordinates: ["latitude": 37.7785, "longitude": -122.4314]
        )
    ]
    
    static let sizes = [
        ("Small", "30 x 30 x 45 cm", 0.5),  // 50% chance for Small
        ("Medium", "45 x 45 x 60 cm", 0.3),  // 30% chance for Medium
        ("Large", "60 x 60 x 90 cm", 0.2)   // 20% chance for Large
    ]
    
    static func clearExistingLockers(completion: @escaping () -> Void) {
        print("🧹 LockerInitializer: Clearing existing lockers...")
        let db = Firestore.firestore()
        
        // Delete all documents in the lockers collection
        db.collection("lockers").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("❌ LockerInitializer: Error getting documents to clear: \(error?.localizedDescription ?? "unknown error")")
                completion()
                return
            }
            
            if documents.isEmpty {
                print("ℹ️ LockerInitializer: No existing lockers found to clear")
                completion()
                return
            }
            
            print("🗑️ LockerInitializer: Found \(documents.count) existing lockers to clear")
            
            let batch = db.batch()
            documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("❌ LockerInitializer: Error clearing lockers: \(error.localizedDescription)")
                } else {
                    print("✅ LockerInitializer: Successfully cleared \(documents.count) lockers")
                }
                completion()
            }
        }
    }

    static func initializeLockers() {
        print("🚀 LockerInitializer: Starting locker initialization...")
        
        // First clear existing lockers, then initialize new ones
        clearExistingLockers {
            let db = Firestore.firestore()
            print("📦 LockerInitializer: Creating 100 lockers across 5 locations...")
            let batch = db.batch()
            
            var sizeCounters = ["Small": 0, "Medium": 0, "Large": 0]
            
            // Distribute 100 lockers across 5 locations (20 each)
            for locationIndex in 0..<5 {
                let location = locations[locationIndex]
                let locationId = location.id // Use fixed location ID
                print("🏪 Creating lockers for location: \(location.name)")
                
                var locationSizeCounters = ["Small": 0, "Medium": 0, "Large": 0]
                
                for lockerIndex in 0..<20 {
                    let lockerId = String(format: "locker_%03d", locationIndex * 20 + lockerIndex + 1)
                    let lockerRef = db.collection("lockers").document(lockerId)
                    
                    // Randomly select size based on probability
                    let randomValue = Double.random(in: 0...1)
                    var selectedSize = sizes[0]
                    var cumulativeProbability = 0.0
                    
                    for size in sizes {
                        cumulativeProbability += size.2
                        if randomValue <= cumulativeProbability {
                            selectedSize = size
                            break
                        }
                    }
                    
                    // Update counters
                    sizeCounters[selectedSize.0, default: 0] += 1
                    locationSizeCounters[selectedSize.0, default: 0] += 1
                    
                    let data: [String: Any] = [
                        "number": String(format: "%03d", locationIndex * 20 + lockerIndex + 1),
                        "size": selectedSize.0,
                        "status": "available",
                        "available": true,
                        "dimensions": selectedSize.1,
                        "pricing": [
                            "standard": [
                                "hourly": 2.99,
                                "daily": 15.00,
                                "weekly": 50.00,
                                "monthly": 150.00
                            ],
                            "premium": [
                                "hourly": 4.99,
                                "daily": 20.00,
                                "weekly": 65.00,
                                "monthly": 180.00
                            ]
                        ],
                        "locationName": location.name,
                        "locationId": locationId,
                        "locationAddress": location.address,
                        "coordinates": location.coordinates,
                        "usage_stats": [
                            "total_rentals": 0,
                            "total_revenue": 0.0,
                            "rental_hours": 0,
                            "standard_rentals": 0,
                            "premium_rentals": 0
                        ],
                        "maintenance": [
                            "last_check": Timestamp(date: Date()),
                            "next_check": Timestamp(date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()),
                            "status": "operational"
                        ],
                        "qr_code": "",
                        "current_rental": "",
                        "created_at": Timestamp(date: Date())
                    ]
                    
                    batch.setData(data, forDocument: lockerRef)
                }
                
                print("  - Created lockers: Small=\(locationSizeCounters["Small"] ?? 0), Medium=\(locationSizeCounters["Medium"] ?? 0), Large=\(locationSizeCounters["Large"] ?? 0)")
            }
            
            print("📊 Total locker distribution: Small=\(sizeCounters["Small"] ?? 0), Medium=\(sizeCounters["Medium"] ?? 0), Large=\(sizeCounters["Large"] ?? 0)")
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("❌ LockerInitializer: Error initializing lockers: \(error.localizedDescription)")
                } else {
                    print("✅ LockerInitializer: Successfully initialized 100 lockers")
                    
                    // Update statistics
                    print("📈 Updating system statistics...")
                    let statsRef = db.collection("statistics").document("system_stats")
                    let updates: [String: Any] = [
                        "locker_stats": [
                            "total": 100,
                            "available": 100,
                            "occupied": 0,
                            "reserved": 0,
                            "maintenance": 0,
                            "distribution": [
                                "Small": sizeCounters["Small"] ?? 50,
                                "Medium": sizeCounters["Medium"] ?? 30,
                                "Large": sizeCounters["Large"] ?? 20
                            ]
                        ],
                        "rental_stats": [
                            "active_rentals": 0,
                            "total_rentals": 0,
                            "rental_types": [
                                "direct": 0,
                                "reservation": 0
                            ],
                            "plan_types": [
                                "standard": 0,
                                "premium": 0
                            ],
                            "duration_types": [
                                "hourly": 0,
                                "daily": 0,
                                "weekly": 0,
                                "monthly": 0
                            ]
                        ],
                        "revenue_stats": [
                            "total_revenue": 0,
                            "today_revenue": 0,
                            "by_size": [
                                "Small": 0,
                                "Medium": 0,
                                "Large": 0
                            ],
                            "by_plan": [
                                "standard": 0,
                                "premium": 0
                            ]
                        ],
                        "last_updated": Timestamp(date: Date())
                    ]
                    
                    statsRef.setData(updates) { error in
                        if let error = error {
                            print("❌ LockerInitializer: Error initializing statistics: \(error.localizedDescription)")
                        } else {
                            print("✅ LockerInitializer: Successfully initialized statistics")
                        }
                    }
                }
            }
        }
    }
} 