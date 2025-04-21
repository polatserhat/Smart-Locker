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
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
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
                
                // Simple processing of rentals
                let allRentals = documents.compactMap { doc -> Rental? in
                    try? doc.data(as: Rental.self)
                }
                
                // Get current date for comparison
                let now = Date()
                
                // Separate current and past rentals
                DispatchQueue.main.async {
                    self.currentRentals = allRentals.filter { rental in
                        let endDate = rental.endDate.dateValue()
                        return endDate > now && rental.status != "cancelled"
                    }
                    
                    self.pastRentals = allRentals.filter { rental in
                        let endDate = rental.endDate.dateValue()
                        return endDate <= now || rental.status == "cancelled"
                    }
                    
                    // Sort rentals by date (newest first)
                    self.currentRentals.sort { $0.startDate.dateValue() > $1.startDate.dateValue() }
                    self.pastRentals.sort { $0.startDate.dateValue() > $1.startDate.dateValue() }
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
} 