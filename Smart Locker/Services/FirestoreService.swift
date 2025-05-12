import Firebase
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Locker Availability
    
    func checkLockerAvailability(
        size: LockerSize,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        db.collection("lockers")
            .whereField("size", isEqualTo: size.rawValue)
            .whereField("status", isEqualTo: "available")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(0))
                    return
                }
                
                completion(.success(documents.count))
            }
    }
    
    func updateLockerStatus(
        lockerId: String,
        status: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let lockerRef = db.collection("lockers").document(lockerId)
        
        lockerRef.updateData([
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getAvailableLockerCount(
        locationId: String,
        size: LockerSize,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        db.collection("lockers")
            .whereField("locationId", isEqualTo: locationId)
            .whereField("size", isEqualTo: size.rawValue)
            .whereField("status", isEqualTo: "available")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(0))
                    return
                }
                
                completion(.success(documents.count))
            }
    }
    
    func getLocationLockerCounts(
        locationId: String,
        completion: @escaping (Result<[String: Int], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var counts: [String: Int] = [:]
        var fetchError: Error?
        
        // Get counts for each size
        for size in LockerSize.allCases {
            group.enter()
            getAvailableLockerCount(locationId: locationId, size: size) { result in
                switch result {
                case .success(let count):
                    counts[size.rawValue] = count
                case .failure(let error):
                    fetchError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(counts))
            }
        }
    }
    
    // MARK: - Reservations
    
    func createReservation(
        userId: String,
        location: LockerLocation,
        size: LockerSize,
        dates: Set<Date>,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // First check locker availability
        checkLockerAvailability(size: size) { result in
            switch result {
            case .success(let availableCount):
                if availableCount == 0 {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No lockers available"])))
                    return
                }
                
                // Continue with reservation if lockers are available
                let reservationRef = self.db.collection("reservations").document()
                
                let reservationData: [String: Any] = [
                    "id": reservationRef.documentID,
                    "userId": userId,
                    "locationId": location.id.uuidString,
                    "locationName": location.name,
                    "locationAddress": location.address,
                    "coordinates": [
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude
                    ],
                    "size": size.rawValue,
                    "dimensions": size.dimensions,
                    "basePrice": size.basePrice,
                    "dates": dates.map { Timestamp(date: $0) },
                    "status": "pending",
                    "createdAt": Timestamp(date: Date())
                ]
                
                reservationRef.setData(reservationData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(reservationRef.documentID))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func confirmReservation(
        reservationId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let reservationRef = db.collection("reservations").document(reservationId)
        
        reservationRef.updateData([
            "status": "confirmed",
            "confirmedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Rentals
    
    func createRental(
        userId: String,
        location: LockerLocation,
        size: LockerSize,
        startDate: Date,
        endDate: Date,
        totalPrice: Double,
        status: String = "pending",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // First find an available locker
        let lockersQuery = db.collection("lockers")
            .whereField("locationId", isEqualTo: location.id.uuidString)
            .whereField("size", isEqualTo: size.rawValue)
            .whereField("status", isEqualTo: "available")
            .limit(to: 1)
        
        print("Querying for available lockers at location: \(location.id.uuidString) with size: \(size.rawValue)")
        
        lockersQuery.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error finding available locker: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let locker = snapshot?.documents.first else {
                print("No available lockers found")
                completion(.failure(NSError(domain: "", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "No lockers available"])))
                return
            }
            
            print("Found available locker with ID: \(locker.documentID)")
            
            let rentalRef = self.db.collection("rentals").document()
            
            let rentalData: [String: Any] = [
                "id": rentalRef.documentID,
                "userId": userId,
                "locationId": location.id.uuidString,
                "locationName": location.name,
                "locationAddress": location.address,
                "coordinates": [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude
                ],
                "size": size.rawValue,
                "dimensions": size.dimensions,
                "startDate": Timestamp(date: startDate),
                "endDate": Timestamp(date: endDate),
                "totalPrice": totalPrice,
                "status": status,
                "lockerId": locker.documentID,
                "createdAt": Timestamp(date: Date())
            ]
            
            // Use transaction only for the actual updates
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                print("Starting transaction to update locker and create rental")
                // Update locker status
                transaction.updateData(
                    ["status": "occupied",
                     "currentRentalId": rentalRef.documentID,
                     "updatedAt": Timestamp(date: Date())],
                    forDocument: locker.reference)
                
                // Create rental
                transaction.setData(rentalData, forDocument: rentalRef)
                
                return rentalRef.documentID
            }) { (result, error) in
                if let error = error {
                    print("Transaction failed: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let rentalId = result as? String {
                    print("Transaction completed successfully")
                    // Update the statistics
                    self.updateStatistics(for: location.id.uuidString, with: size.rawValue)
                    completion(.success(rentalId))
                }
            }
        }
    }
    
    // Helper method to update statistics when a rental is created
    private func updateStatistics(for locationId: String, with size: String) {
        let statsRef = db.collection("statistics").document("system_stats")
        
        statsRef.getDocument { [weak self] (document, error) in
            guard let _ = self, let document = document, document.exists else {
                print("Statistics document doesn't exist")
                return
            }
            
            self?.db.runTransaction({ (transaction, errorPointer) -> Any? in
                // Get current statistics
                do {
                    let statsDocument = try transaction.getDocument(statsRef)
                    
                    // Update locker stats
                    var updates: [String: Any] = [
                        "locker_stats.available": FieldValue.increment(Int64(-1)),
                        "locker_stats.occupied": FieldValue.increment(Int64(1)),
                        "rental_stats.active_rentals": FieldValue.increment(Int64(1)),
                        "rental_stats.total_rentals": FieldValue.increment(Int64(1)),
                        "last_updated": Timestamp(date: Date())
                    ]
                    
                    transaction.updateData(updates, forDocument: statsRef)
                    
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }) { (_, error) in
                if let error = error {
                    print("Failed to update statistics: \(error.localizedDescription)")
                } else {
                    print("Statistics updated successfully")
                }
            }
        }
    }
    
    func updateRentalStatus(
        rentalId: String,
        status: String,
        finalPrice: Double? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let rentalRef = db.collection("rentals").document(rentalId)
        
        var updateData: [String: Any] = [
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let finalPrice = finalPrice {
            updateData["totalPrice"] = finalPrice
            updateData["endDate"] = Timestamp(date: Date())
        }
        
        rentalRef.updateData(updateData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // If rental is completed, update locker status
                if status == "completed" {
                    // Get the rental to find the locker ID
                    rentalRef.getDocument { (document, error) in
                        if let document = document,
                           let lockerId = document.data()?["lockerId"] as? String {
                            // Update locker status to available
                            self.updateLockerStatus(
                                lockerId: lockerId,
                                status: "available"
                            ) { _ in }
                        }
                    }
                }
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetchUserReservations(
        userId: String,
        completion: @escaping (Result<[Reservation], Error>) -> Void
    ) {
        db.collection("reservations")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let reservations = documents.compactMap { document -> Reservation? in
                    guard let data = try? document.data(as: Reservation.self) else {
                        return nil
                    }
                    return data
                }
                
                completion(.success(reservations))
            }
    }
    
    func fetchUserRentals(
        userId: String,
        completion: @escaping (Result<[Rental], Error>) -> Void
    ) {
        db.collection("rentals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let rentals = documents.map { document in
                    Rental(snapshot: document)
                }
                
                completion(.success(rentals))
            }
    }
    
    func getRental(id: String, completion: @escaping (Result<Rental?, Error>) -> Void) {
        let document = db.collection("rentals").document(id)
        document.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.success(nil))
                return
            }
            
            let rental = Rental(snapshot: document)
            completion(.success(rental))
        }
    }
    
    // MARK: - Admin Utilities
    
    func validateAndUpdateLockerCounts() {
        // This method checks if the lockers in Firebase match our expected counts
        // and updates the statistics collection
        
        // Get current locker counts by size
        let sizes = ["Small", "Medium", "Large"]
        let group = DispatchGroup()
        var counts: [String: Int] = [:]
        var statuses: [String: Int] = [:]
        
        // Count by size
        for size in sizes {
            group.enter()
            db.collection("lockers")
                .whereField("size", isEqualTo: size)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        counts[size] = documents.count
                        
                        // Count by status for this size
                        let available = documents.filter { $0.data()["status"] as? String == "available" }.count
                        let occupied = documents.filter { $0.data()["status"] as? String == "occupied" }.count
                        let reserved = documents.filter { $0.data()["status"] as? String == "reserved" }.count
                        let maintenance = documents.filter { $0.data()["status"] as? String == "maintenance" }.count
                        
                        statuses["\(size)_available"] = available
                        statuses["\(size)_occupied"] = occupied
                        statuses["\(size)_reserved"] = reserved
                        statuses["\(size)_maintenance"] = maintenance
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            // Calculate totals
            let totalLockers = counts.values.reduce(0, +)
            let totalAvailable = statuses.filter { $0.key.contains("_available") }.values.reduce(0, +)
            let totalOccupied = statuses.filter { $0.key.contains("_occupied") }.values.reduce(0, +)
            let totalReserved = statuses.filter { $0.key.contains("_reserved") }.values.reduce(0, +)
            let totalMaintenance = statuses.filter { $0.key.contains("_maintenance") }.values.reduce(0, +)
            
            // Update statistics collection
            let _ = self.db.collection("statistics").document("system_stats")
            let updates: [String: Any] = [
                "locker_stats.total": totalLockers,
                "locker_stats.available": totalAvailable,
                "locker_stats.occupied": totalOccupied,
                "locker_stats.reserved": totalReserved,
                "locker_stats.maintenance": totalMaintenance,
                "locker_stats.distribution.Small": counts["Small"] ?? 0,
                "locker_stats.distribution.Medium": counts["Medium"] ?? 0,
                "locker_stats.distribution.Large": counts["Large"] ?? 0,
                "last_updated": Timestamp(date: Date())
            ]
            
            self.db.collection("statistics").document("system_stats").updateData(updates) { error in
                if let error = error {
                    print("Error updating statistics: \(error.localizedDescription)")
                } else {
                    print("Statistics updated successfully")
                    print("Total lockers: \(totalLockers)")
                    print("Available: \(totalAvailable)")
                    print("Occupied: \(totalOccupied)")
                    print("Reserved: \(totalReserved)")
                    print("Maintenance: \(totalMaintenance)")
                }
            }
        }
    }
} 