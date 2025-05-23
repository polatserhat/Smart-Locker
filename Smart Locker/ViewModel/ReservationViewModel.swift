import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ReservationViewModel: ObservableObject {
    @Published var currentRentals: [Rental] = []
    @Published var pastRentals: [Rental] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        // Listen for auth changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchRentals(for: user.uid)
            } else {
                self?.clearRentals()
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchRentals(for userId: String) {
        isLoading = true
        errorMessage = nil
        
        // Remove any existing listener
        listenerRegistration?.remove()
        
        // Listen for rentals in real-time from Firebase
        listenerRegistration = db.collection("rentals")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                // Process rentals using the new initializer
                let allRentals = documents.map { doc in
                    Rental(snapshot: doc)
                }
                
                // Get current date for comparison
                let now = Date()
                
                // Separate current and past rentals
                DispatchQueue.main.async {
                    self.currentRentals = allRentals.filter { rental in
                        // Include all active status rentals regardless of end date
                        return rental.status == "active" || 
                            (rental.endDate > now && rental.status != "cancelled" && rental.status != "completed")
                    }
                    
                    self.pastRentals = allRentals.filter { rental in
                        return rental.status == "completed" || rental.status == "cancelled" ||
                            (rental.endDate <= now && rental.status != "active")
                    }
                    
                    // Sort rentals by date (newest first)
                    self.currentRentals.sort { $0.startDate > $1.startDate }
                    self.pastRentals.sort { $0.startDate > $1.startDate }
                }
            }
    }
    
    private func clearRentals() {
        currentRentals = []
        pastRentals = []
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    // Get count of current rentals
    var currentRentalCount: Int {
        return currentRentals.count
    }
    
    // Get count of past rentals
    var pastRentalCount: Int {
        return pastRentals.count
    }
    
    // Method to force refresh rentals
    func refreshRentals() {
        if let user = Auth.auth().currentUser {
            fetchRentals(for: user.uid)
        }
    }
    
    // Method to mark a rental as completed and move it to past rentals
    func completeRental(rentalId: String) {
        // Find the rental in currentRentals
        if let index = currentRentals.firstIndex(where: { $0.id == rentalId }) {
            // Move it to pastRentals
            let rental = currentRentals[index]
            currentRentals.remove(at: index)
            pastRentals.insert(rental, at: 0)
            
            // Update the rental status in Firestore
            db.collection("rentals").document(rentalId).updateData([
                "status": "completed",
                "endDate": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error updating rental status: \(error.localizedDescription)")
                }
            }
            
            // Update the locker availability count
            updateLockerAvailability(for: rental)
        }
    }
    
    // Helper method to update locker availability
    private func updateLockerAvailability(for rental: Rental) {
        // Get the location document
        db.collection("locations")
            .whereField("name", isEqualTo: rental.locationName)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding location: \(error.localizedDescription)")
                    return
                }
                
                guard let locationDoc = snapshot?.documents.first else {
                    print("Location not found")
                    return
                }
                
                // Update the available locker count
                let lockerSize = rental.size.lowercased()
                let locationRef = locationDoc.reference
                
                // Increment the available count for this size
                locationRef.updateData([
                    "availableLockers.\(lockerSize)": FieldValue.increment(Int64(-1))
                ]) { error in
                    if let error = error {
                        print("Error updating locker availability: \(error.localizedDescription)")
                    } else {
                        print("Successfully decremented available locker count for \(lockerSize)")
                        
                        // Post notification to refresh the locker map
                        NotificationCenter.default.post(name: Notification.Name("RefreshLockerMap"), object: nil)
                    }
                }
            }
    }
} 