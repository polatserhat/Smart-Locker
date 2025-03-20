import Firebase
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Reservations
    
    func createReservation(
        userId: String,
        location: LockerLocation,
        size: LockerSize,
        dates: Set<Date>,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let reservationRef = db.collection("reservations").document()
        
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
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let rentalRef = db.collection("rentals").document()
        
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
            "status": "active",
            "createdAt": Timestamp(date: Date())
        ]
        
        rentalRef.setData(rentalData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(rentalRef.documentID))
            }
        }
    }
    
    func updateRentalStatus(
        rentalId: String,
        status: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let rentalRef = db.collection("rentals").document(rentalId)
        
        rentalRef.updateData([
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
                
                let rentals = documents.compactMap { document -> Rental? in
                    guard let data = try? document.data(as: Rental.self) else {
                        return nil
                    }
                    return data
                }
                
                completion(.success(rentals))
            }
    }
} 