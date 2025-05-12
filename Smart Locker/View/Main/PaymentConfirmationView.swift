import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore


struct PaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    @State private var isCreatingRental = false
    @State private var showSuccess = false
    @State private var error: String?
    @State private var showError = false
    
    let rental: LockerRental
    let location: LockerLocation
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.primaryBlack)
                }
                
                Spacer()
                
                Text("Start Rental")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Balance spacing
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.top, 20)
            
            // Rental details card
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primaryYellow)
                    .padding(.bottom, 10)
                
                Text("Hourly Rental Ready")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your locker is ready to use. Your rental will begin once you click 'Start Rental' below.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 10)
                
                // Location info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(rental.shopName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Locker info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Locker Size")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(rental.size.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Rate")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("$\(String(format: "%.2f", rental.size.basePrice))/hour")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primaryYellow)
                    }
                }
                .padding(.bottom, 8)
                
                // Start time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.primaryYellow)
                        
                        Text(Date(), style: .time)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            
            Spacer()
            
            // Important Note
            VStack(spacing: 8) {
                Text("Important Note")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryBlack)
                
                Text("You will be charged based on the actual usage time when you end the rental. The hourly rate will be applied to calculate the final amount.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            
            // Start Rental Button
            Button(action: {
                startRental()
            }) {
                HStack {
                    Text("START RENTAL")
                        .fontWeight(.bold)
                    
                    if isCreatingRental {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.leading, 5)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primaryYellow)
                .foregroundColor(AppColors.primaryBlack)
                .cornerRadius(14)
                .shadow(color: AppColors.primaryYellow.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
            .disabled(isCreatingRental)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(error ?? "Something went wrong. Please try again."),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showSuccess) {
            RentalSuccessView()
        }
    }
    
    private func startRental() {
        guard let user = authViewModel.currentUser else {
            error = "You must be logged in to rent a locker."
            showError = true
            return
        }
        
        isCreatingRental = true
        let db = Firestore.firestore()
        
        // 1. Find an available locker
        db.collection("lockers")
            .whereField("locationName", isEqualTo: location.name)
            .whereField("size", isEqualTo: rental.size.rawValue)
            .whereField("available", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.error = "Error finding locker: \(error.localizedDescription)"
                    self.showError = true
                    self.isCreatingRental = false
                    return
                }
                
                guard let locker = snapshot?.documents.first else {
                    self.error = "No available lockers found"
                    self.showError = true
                    self.isCreatingRental = false
                    return
                }
                
                print("Found available locker: \(locker.documentID)")
                
                // 2. Create rental and update locker status
                let batch = db.batch()
                let rentalRef = db.collection("rentals").document()
                let startDate = Date()
                
                // Rental data
                let rentalData: [String: Any] = [
                    "id": rentalRef.documentID,
                    "userId": user.id,
                    "lockerId": locker.documentID,
                    "locationId": location.id.uuidString,
                    "locationName": location.name,
                    "locationAddress": location.address,
                    "size": rental.size.rawValue,
                    "startDate": Timestamp(date: startDate),
                    "endDate": Timestamp(date: startDate.addingTimeInterval(12 * 3600)), // 12 hours max
                    "status": "active",
                    "createdAt": Timestamp(date: startDate),
                    "updatedAt": Timestamp(date: startDate)
                ]
                
                // Set the rental data
                batch.setData(rentalData, forDocument: rentalRef)
                
                // Update locker status and availability
                batch.updateData([
                    "available": false,
                    "status": "occupied",
                    "currentRentalId": rentalRef.documentID,
                    "updatedAt": Timestamp(date: startDate)
                ], forDocument: locker.reference)
                
                // Update statistics
                let statsRef = db.collection("statistics").document("system_stats")
                batch.updateData([
                    "locker_stats.available": FieldValue.increment(Int64(-1)),
                    "locker_stats.occupied": FieldValue.increment(Int64(1)),
                    "rental_stats.active_rentals": FieldValue.increment(Int64(1)),
                    "last_updated": Timestamp(date: startDate)
                ], forDocument: statsRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error creating rental: \(error.localizedDescription)")
                        self.error = "Error creating rental: \(error.localizedDescription)"
                        self.showError = true
                        self.isCreatingRental = false
                    } else {
                        print("Successfully created rental with ID: \(rentalRef.documentID)")
                        self.isCreatingRental = false
                        self.showSuccess = true
                        
                        // Update the view model and refresh the map
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.reservationViewModel.fetchRentals(for: user.id)
                            NotificationCenter.default.post(name: NSNotification.Name("RefreshLockerMap"), object: nil)
                            self.dismiss()
                        }
                    }
                }
            }
    }
}

#Preview {
    let rental = LockerRental(
        id: "preview_rental_123",
        shopName: "Smart Locker Shop - A-101",
        size: .medium,
        rentalType: .instant,
        startTime: Date()
    )
    
    let location = LockerLocation(
        name: "Smart Locker Shop - A-101",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        address: "123 Market St, San Francisco, CA 94105"
    )
    
    return PaymentConfirmationView(rental: rental, location: location)
        .environmentObject(AuthViewModel())
} 
