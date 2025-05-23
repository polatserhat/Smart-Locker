import SwiftUI
import FirebaseFirestore
import MapKit

// MARK: - Profile Image Helper
extension UserDefaults {
    static func getProfileImage(for userId: String? = nil) -> UIImage? {
        // First try user-specific image if we have a user ID
        if let userId = userId, 
           let imageData = UserDefaults.standard.data(forKey: "userProfileImage_\(userId)"),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // Fall back to generic key
        if let imageData = UserDefaults.standard.data(forKey: "userProfileImage"),
           let image = UIImage(data: imageData) {
            return image
        }
        
        return nil
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.secondary : AppColors.surface)
            )
        }
    }
}

struct HomeView: View {
    @State private var selectedCategory = 0
    @State private var showLockerMap = false
    @State private var showReservation = false
    @State private var showProfile = false
    @State private var showPlansInfo = false
    @State private var showPastRentals = false
    @State private var showPayment = false
    @State private var showPaymentConfirmation = false
    @State private var currentRentalTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var calculatedAmount: Double = 0
    @State private var selectedRental: LockerRental?
    @State private var selectedLocation: LockerLocation?
    @State private var localProfileImage: UIImage? = nil
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    
    // MARK: - Private Functions for Rental Management
    
    private func calculateTotalHours(from startTime: Date, to endTime: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: endTime)
        return Double(components.hour ?? 0) + (Double(components.minute ?? 0) / 60.0)
    }
    
    private func updateRentalDocument(db: Firestore, rentalId: String, endTime: Date, finalPrice: Double) -> DocumentReference {
        let rentalRef = db.collection("rentals").document(rentalId)
        return rentalRef
    }
    
    private func updateLockerStatus(db: Firestore, lockerId: String, endTime: Date) -> DocumentReference {
        let lockerRef = db.collection("lockers").document(lockerId)
        return lockerRef
    }
    
    private func getStatisticsReference(db: Firestore) -> DocumentReference {
        return db.collection("statistics").document("system_stats")
    }
    
    private func startTimer(for rental: Rental) {
        // Stop any existing timer first
        stopTimer()
        
        // Calculate initial elapsed time
        elapsedTime = Date().timeIntervalSince(rental.startDate)
        
        // Create a new timer that fires every second
        currentRentalTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedTime = Date().timeIntervalSince(rental.startDate)
        }
        
        // Add the timer to RunLoop to ensure it runs properly
        if let timer = currentRentalTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        currentRentalTimer?.invalidate()
        currentRentalTimer = nil
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func endActiveRental(activeRental: Rental) {
        print("🔴 endActiveRental called for rental: \(activeRental.id)")
        stopTimer()
        
        // Create a LockerRental object from the active rental
        let lockerRental = LockerRental(
            id: activeRental.id,
            shopName: activeRental.locationName,
            size: LockerSize(rawValue: activeRental.size) ?? .medium,
            rentalType: .instant,
            startTime: activeRental.startDate,
            endTime: Date(),
            status: .active,
            totalPrice: calculateFinalPrice(startTime: activeRental.startDate, endTime: Date(), basePrice: activeRental.size == "Small" ? 0.10 : (activeRental.size == "Medium" ? 0.15 : 0.20))
        )
        
        // Create a LockerLocation object
        let lockerLocation = LockerLocation(
            name: activeRental.locationName,
            coordinate: CLLocationCoordinate2D(
                latitude: 37.7749, // Default to San Francisco if coordinates not available
                longitude: -122.4194
            ),
            address: activeRental.locationName
        )
        
        // Set the selected rental and location
        self.selectedRental = lockerRental
        self.selectedLocation = lockerLocation
        
        // Show payment view
        self.showPayment = true
    }
    
    private func calculateFinalPrice(startTime: Date, endTime: Date, basePrice: Double) -> Double {
        let totalHours = calculateTotalHours(from: startTime, to: endTime)
        return max(basePrice * totalHours, basePrice) // Minimum of 1 hour
    }
    
    private func fetchLockerPricing(db: Firestore, lockerId: String, activeRental: Rental, endTime: Date, totalHours: Double) {
        db.collection("lockers")
            .document(lockerId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching locker: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let pricing = data["pricing"] as? [String: Any],
                      let standardPricing = pricing["standard"] as? [String: Any],
                      let hourlyRate = standardPricing["hourly"] as? Double else {
                    print("Error getting pricing data")
                    return
                }
                
                let finalPrice = max(hourlyRate * totalHours, hourlyRate) // Minimum of 1 hour
                
                // Format price for display
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.maximumFractionDigits = 2
                
                let priceString = formatter.string(from: NSNumber(value: finalPrice)) ?? "$\(String(format: "%.2f", finalPrice))"
                let hoursString = String(format: "%.1f", totalHours)
                
                // Perform the update operations
                completeRentalEnd(db: db, activeRental: activeRental, endTime: endTime, finalPrice: finalPrice, totalHours: totalHours)
            }
    }
    
    private func completeRentalEnd(db: Firestore, activeRental: Rental, endTime: Date, finalPrice: Double, totalHours: Double) {
        // Update rental status and price
        let batch = db.batch()
        
        // 1. Update rental document
        let rentalRef = updateRentalDocument(db: db, rentalId: activeRental.id, endTime: endTime, finalPrice: finalPrice)
        batch.updateData([
            "status": "completed",
            "endDate": Timestamp(date: endTime),
            "totalPrice": finalPrice,
            "updatedAt": Timestamp(date: endTime)
        ], forDocument: rentalRef)
        
        // 2. Update locker status
        let lockerRef = updateLockerStatus(db: db, lockerId: activeRental.lockerId, endTime: endTime)
        batch.updateData([
            "status": "available",
            "available": true,
            "currentRentalId": nil,
            "updatedAt": Timestamp(date: endTime)
        ], forDocument: lockerRef)
        
        // 3. Update statistics
        let statsRef = getStatisticsReference(db: db)
        updateStatistics(batch: batch, statsRef: statsRef, activeRental: activeRental, finalPrice: finalPrice, totalHours: totalHours)
        
        // 4. Update available locker count
        updateAvailableLockerCount(batch: batch, db: db, activeRental: activeRental)
        
        // 5. Commit the batch
        commitBatchUpdates(batch: batch, db: db)
    }
    
    private func updateStatistics(batch: WriteBatch, statsRef: DocumentReference, activeRental: Rental, finalPrice: Double, totalHours: Double) {
        batch.updateData([
            "locker_stats.available": FieldValue.increment(Int64(1)),
            "locker_stats.occupied": FieldValue.increment(Int64(-1)),
            "rental_stats.active_rentals": FieldValue.increment(Int64(-1)),
            "revenue_stats.total_revenue": FieldValue.increment(finalPrice),
            "revenue_stats.today_revenue": FieldValue.increment(finalPrice),
            "revenue_stats.by_size.\(activeRental.size)": FieldValue.increment(finalPrice),
            "revenue_stats.by_plan.standard": FieldValue.increment(finalPrice),
            "usage_stats.total_rentals": FieldValue.increment(Int64(1)),
            "usage_stats.rental_hours": FieldValue.increment(Int64(ceil(totalHours))),
            "usage_stats.standard_rentals": FieldValue.increment(Int64(1)),
            "usage_stats.total_revenue": FieldValue.increment(finalPrice)
        ], forDocument: statsRef)
    }
    
    private func updateAvailableLockerCount(batch: WriteBatch, db: Firestore, activeRental: Rental) {
        // We need to get the locationId for this locker first
        // This should be improved with separate functions and proper error handling
        // For now, we'll just add a basic update on the locker document itself
        
        // Skip the locationId lookup for brevity - this would ideally be a proper lookup
        batch.updateData([
            "availableLockers.\(activeRental.size.lowercased())": FieldValue.increment(Int64(1))
        ], forDocument: db.collection("lockers").document(activeRental.lockerId))
    }
    
    private func commitBatchUpdates(batch: WriteBatch, db: Firestore) {
        batch.commit { error in
            if let error = error {
                print("Error ending rental: \(error.localizedDescription)")
            } else {
                print("Rental ended successfully")
                
                // Update statistics
                updateStatisticsAfterCommit(db: db)
            }
        }
    }
    
    private func updateStatisticsAfterCommit(db: Firestore) {
        db.collection("statistics").document("system_stats").updateData([
            "locker_stats.available": FieldValue.increment(Int64(1)),
            "locker_stats.occupied": FieldValue.increment(Int64(-1)),
            "rental_stats.active_rentals": FieldValue.increment(Int64(-1))
        ])
    }
    
    // Return to home screen after payment complete
    private func refreshData() {
        // Refresh the rentals list
        if let userId = authViewModel.currentUser?.id {
            reservationViewModel.fetchRentals(for: userId)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section with Profile
                HStack {
                    Button(action: {
                        showProfile = true
                    }) {
                        if let localImage = localProfileImage {
                            Image(uiImage: localImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.secondary.opacity(0.5), lineWidth: 1))
                        } else if let user = authViewModel.currentUser {
                            Image("profile_placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.secondary.opacity(0.5), lineWidth: 1))
                        } else {
                            Image("profile_placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.secondary.opacity(0.5), lineWidth: 1))
                        }
                    }
                    
                    Spacer()
                    
                    // View Plans Button
                    Button(action: {
                        showPlansInfo = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                            Text("Plans")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.secondary, lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Greeting and Title
                VStack(spacing: 8) {
                    Text("Hello, \(authViewModel.currentUser?.name ?? "User")")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                    
                    VStack(spacing: 0) {
                        Text("Smart")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Locker")
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(AppColors.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Main Content Section
                VStack(spacing: 16) {
                    // Active Rental Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Rental")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if let activeRental = reservationViewModel.currentRentals.first {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activeRental.locationName)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("\(activeRental.size) Locker")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Timer display
                                    Text(formatElapsedTime(elapsedTime))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.secondary)
                                        .monospacedDigit()
                                }
                                .onAppear {
                                    startTimer(for: activeRental)
                                }
                                .onDisappear {
                                    stopTimer()
                                }
                                
                                if activeRental.status == "active" {
                                    Button(action: {
                                        print("🔴 End Rental button pressed")
                                        endActiveRental(activeRental: activeRental)
                                    }) {
                                        Text("End Rental")
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(AppColors.error)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                            .background(AppColors.surface)
                            .cornerRadius(12)
                            .shadow(color: AppColors.background.opacity(0.5), radius: 8, x: 0, y: 4)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No active rental")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Your locker rentals will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.secondary)
                            }
                            .padding()
                            .background(AppColors.surface)
                            .cornerRadius(12)
                            .shadow(color: AppColors.background.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // Upcoming Rental Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Rental")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        // TODO: Replace with actual upcoming rental data from reservationViewModel
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No upcoming rental")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Your reservations will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.secondary)
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .shadow(color: AppColors.background.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    
                    // Past Rentals Section
                    Button(action: {
                        showPastRentals = true
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past Rentals")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View History")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Check your rental history")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.secondary)
                            }
                            .padding()
                            .background(AppColors.surface)
                            .cornerRadius(12)
                            .shadow(color: AppColors.background.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Direct Rent Button
                        Button(action: {
                            showLockerMap = true
                        }) {
                            HStack {
                                Text("DIRECT RENT")
                                    .fontWeight(.bold)
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 20))
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.secondary)
                            .cornerRadius(16)
                            .shadow(color: AppColors.secondary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        // Reservation Button
                        Button(action: {
                            showReservation = true
                        }) {
                            HStack {
                                Text("RESERVATION")
                                    .fontWeight(.bold)
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(16)
                            .shadow(color: AppColors.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .background(AppColors.background)
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showLockerMap) {
                LockerMapView()
            }
            .fullScreenCover(isPresented: $showReservation) {
                ReservationDateSelectionView()
            }
            .fullScreenCover(isPresented: $showProfile) {
                ProfilePageView()
            }
            .fullScreenCover(isPresented: $showPlansInfo) {
                PlanSelectionView(isInformationOnly: true)
            }
            .fullScreenCover(isPresented: $showPastRentals) {
                RentalHistoryView()
                    .environmentObject(reservationViewModel)
            }
            .fullScreenCover(isPresented: $showPayment) {
                Group {
                    if let rental = selectedRental, let location = selectedLocation {
                        PaymentView(rental: rental, location: location)
                    } else {
                        Text("Error loading payment view")
                            .padding()
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaymentConfirmation) {
                if let rental = selectedRental, let location = selectedLocation {
                    PaymentConfirmationView(rental: rental, location: location)
                        .environmentObject(authViewModel)
                        .environmentObject(reservationViewModel)
                        .onDisappear {
                            refreshData()
                            
                            // Reset state if needed
                            selectedRental = nil
                            selectedLocation = nil
                        }
                }
            }
            .onChange(of: showPayment) { newValue in
                if newValue {
                    if let rental = selectedRental, let location = selectedLocation {
                        print("🔴 Presenting PaymentView with rental: \(rental.id)")
                    } else {
                        print("🔴 Error: selectedRental or selectedLocation is nil")
                    }
                }
            }
            .onAppear {
                // Load profile image from UserDefaults
                loadProfileImage()
                
                // Start timer for active rental when view appears
                if let activeRental = reservationViewModel.currentRentals.first {
                    startTimer(for: activeRental)
                }
            }
            .onDisappear {
                // Stop timer when view disappears
                stopTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissToRoot"))) { _ in
                // Dismiss all presented views
                DispatchQueue.main.async {
                    showLockerMap = false
                    showReservation = false
                    showProfile = false
                    showPlansInfo = false
                    showPastRentals = false
                    showPayment = false
                    showPaymentConfirmation = false
                    
                    // Reset rental states
                    selectedRental = nil
                    selectedLocation = nil
                    
                    // Stop the timer when the rental is completed
                    stopTimer()
                    elapsedTime = 0
                    
                    // Force refresh the rentals list to clear completed rentals
                    if let userId = authViewModel.currentUser?.id {
                        // Clear the current rentals immediately to remove the timer display
                        reservationViewModel.currentRentals = []
                        // Then fetch updated data from Firebase
                        reservationViewModel.fetchRentals(for: userId)
                    }
                }
            }
            // Listen for profile image updates
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { _ in
                loadProfileImage()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Profile Image Helper
    private func loadProfileImage() {
        localProfileImage = UserDefaults.getProfileImage(for: authViewModel.currentUser?.id)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(ReservationViewModel())
            .preferredColorScheme(.dark)
    }
}
