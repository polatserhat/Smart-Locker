import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore


struct PaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    @State private var isCreatingRental = false
    @State private var isCompletingRental = false
    @State private var showSuccess = false
    @State private var error: String?
    @State private var showError = false
    
    let rental: LockerRental
    let location: LockerLocation
    
    // Check if this is a new rental or completing an existing one
    private var isCompletingExistingRental: Bool {
        return rental.startTime != nil && rental.status == .active
    }
    
    // Dynamic title based on rental state
    private var pageTitle: String {
        return isCompletingExistingRental ? "Complete Rental" : "Start Rental"
    }
    
    // Dynamic button text based on rental state
    private var actionButtonText: String {
        return isCompletingExistingRental ? "COMPLETE RENTAL" : "START RENTAL"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(AppColors.primary)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Text(pageTitle)
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
                Image(systemName: isCompletingExistingRental ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.secondary)
                    .padding(.bottom, 10)
                
                Text(isCompletingExistingRental ? "Rental Completion" : "Hourly Rental Ready")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if isCompletingExistingRental {
                    Text("Your rental is complete. Click 'Complete Rental' to finalize and process payment.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    Text("Your locker is ready to use. Your rental will begin once you click 'Start Rental' below.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                // Location info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(rental.shopName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Locker info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Locker Size")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(rental.size.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Rate")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("$\(String(format: "%.2f", rental.size.basePrice))/hour")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 8)
                
                // Start time or duration info
                if isCompletingExistingRental, let startTime = rental.startTime {
                    // Duration information for completing rental
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rental Duration")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        let duration = calculateDuration(from: startTime, to: Date())
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(AppColors.secondary)
                            
                            Text(duration)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Total cost
                    if let totalPrice = rental.totalPrice {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Cost")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(AppColors.secondary)
                                
                                Text("$\(String(format: "%.2f", totalPrice))")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // Start time for new rental
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Time")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(AppColors.secondary)
                            
                            Text(Date(), style: .time)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                    .foregroundColor(AppColors.textPrimary)
                
                if isCompletingExistingRental {
                    Text("Once you complete this rental, your payment method will be charged based on your usage time. The locker will become available for other users.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("You will be charged based on the actual usage time when you end the rental. The hourly rate will be applied to calculate the final amount.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            
            // Start/Complete Rental Button
            Button(action: {
                if isCompletingExistingRental {
                    completeRental()
                } else {
                    // We're now using the PlanSelectionView for starting rentals
                    // This should never get called now
                    dismiss()
                }
            }) {
                HStack {
                    Text(actionButtonText)
                        .fontWeight(.bold)
                    
                    if isCompletingRental {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.leading, 5)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.secondary)
                .foregroundColor(AppColors.primary)
                .cornerRadius(14)
                .shadow(color: AppColors.secondary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
            .disabled(isCompletingRental)
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
            RentalSuccessView(
                isCompletingRental: isCompletingExistingRental,
                rental: rental,
                duration: isCompletingExistingRental ? calculateDuration(from: rental.startTime ?? Date(), to: Date()) : nil,
                totalAmount: rental.totalPrice,
                hourlyRate: rental.size.basePrice
            )
        }
    }
    
    // Calculate duration string
    private func calculateDuration(from startDate: Date, to endDate: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") \(minutes) minute\(minutes > 1 ? "s" : "")"
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
    
    private func completeRental() {
        guard let user = authViewModel.currentUser else {
            error = "You must be logged in to complete the rental."
            showError = true
            return
        }
        
        isCompletingRental = true
        let db = Firestore.firestore()
        
        // Find the actual active rental document
        db.collection("rentals")
            .whereField("userId", isEqualTo: user.id)
            .whereField("status", isEqualTo: "active")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.error = "Error finding rental: \(error.localizedDescription)"
                    self.showError = true
                    self.isCompletingRental = false
                    return
                }
                
                guard let rentalDoc = snapshot?.documents.first else {
                    self.error = "Active rental not found"
                    self.showError = true
                    self.isCompletingRental = false
                    return
                }
                
                // Get the locker ID from the rental
                guard let lockerId = rentalDoc.data()["lockerId"] as? String else {
                    self.error = "Locker information missing"
                    self.showError = true
                    self.isCompletingRental = false
                    return
                }
                
                print("Found rental to complete: \(rentalDoc.documentID) with locker: \(lockerId)")
                
                // Complete the rental with batch operations
                let batch = db.batch()
                let rentalRef = rentalDoc.reference
                let endDate = Date()
                
                // Update rental status
                batch.updateData([
                    "status": "completed",
                    "endDate": Timestamp(date: endDate),
                    "totalPrice": rental.totalPrice ?? 0,
                    "updatedAt": Timestamp(date: endDate)
                ], forDocument: rentalRef)
                
                // Update locker status and availability
                let lockerRef = db.collection("lockers").document(lockerId)
                batch.updateData([
                    "available": true,
                    "status": "available",
                    "currentRentalId": nil,
                    "updatedAt": Timestamp(date: endDate)
                ], forDocument: lockerRef)
                
                // Update statistics
                let statsRef = db.collection("statistics").document("system_stats")
                batch.updateData([
                    "locker_stats.available": FieldValue.increment(Int64(1)),
                    "locker_stats.occupied": FieldValue.increment(Int64(-1)),
                    "rental_stats.active_rentals": FieldValue.increment(Int64(-1)),
                    "revenue_stats.total_revenue": FieldValue.increment(rental.totalPrice ?? 0),
                    "revenue_stats.today_revenue": FieldValue.increment(rental.totalPrice ?? 0),
                    "last_updated": Timestamp(date: endDate)
                ], forDocument: statsRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error completing rental: \(error.localizedDescription)")
                        self.error = "Error completing rental: \(error.localizedDescription)"
                        self.showError = true
                        self.isCompletingRental = false
                    } else {
                        print("Successfully completed rental with ID: \(rentalRef.documentID)")
                        self.isCompletingRental = false
                        
                        // Post a notification to refresh the available lockers
                        NotificationCenter.default.post(name: Notification.Name("RefreshLockerMap"), object: nil)
                        
                        // Update the view model
                        self.reservationViewModel.fetchRentals(for: user.id)
                        
                        // Show success view
                        self.showSuccess = true
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
