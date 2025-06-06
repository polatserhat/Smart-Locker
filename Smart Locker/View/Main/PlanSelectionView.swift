import SwiftUI
import MapKit
import FirebaseFirestore

struct PlanSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTier: PlanTier = .standard
    @State private var selectedDuration: PlanDuration = .hourly
    @State private var showConfirmation = false
    @State private var showPlanRequiredHint = false
    @State private var showRentalSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
    let rental: LockerRental
    let location: LockerLocation
    let isInformationOnly: Bool
    
    // Calculate total price based on duration
    private var totalPrice: Double {
        selectedDuration.getPrice(for: selectedTier)
    }
    
    // Helper computed properties to break down complex expressions
    private var navigationTitle: String {
        isInformationOnly ? "Available Plans" : "Select a Plan"
    }
    
    private var tierBackgroundColor: (PlanTier) -> Color {
        { tier in
            selectedTier == tier
            ? (tier == .premium ? AppColors.secondary : Color.blue)
            : AppColors.surface
        }
    }
    
    private var tierTextColor: (PlanTier) -> Color {
        { tier in
            selectedTier == tier ? AppColors.textPrimary : AppColors.textPrimary
        }
    }
    
    private var tierBorderColor: (PlanTier) -> Color {
        { tier in
            selectedTier == tier
            ? Color.clear
            : (tier == .premium ? AppColors.secondary : Color.blue).opacity(0.3)
        }
    }
    
    private var durationBorderColor: (PlanDuration) -> Color {
        { duration in
            selectedDuration == duration
            ? (selectedTier == .premium ? AppColors.secondary : Color.blue)
            : AppColors.textSecondary.opacity(0.2)
        }
    }
    
    private var durationBorderWidth: (PlanDuration) -> CGFloat {
        { duration in
            selectedDuration == duration ? 2 : 1
        }
    }
    
    init(rental: LockerRental? = nil, location: LockerLocation? = nil, isInformationOnly: Bool = false) {
        // Initialize rental
        if let rental = rental {
            self.rental = rental
        } else {
            // Create a default rental with minimal initialization
            let defaultRental = LockerRental(
                id: "",
                shopName: "",
                size: .medium,
                rentalType: .instant,
                reservationDate: nil
            )
            self.rental = defaultRental
        }

        // Initialize location
        if let location = location {
            self.location = location
        } else {
            // Create a default location with minimal initialization
            let defaultLocation = LockerLocation(
                name: "",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                address: ""
            )
            self.location = defaultLocation
        }

        self.isInformationOnly = isInformationOnly
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            // Divider
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 8)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    planTierSection
                    
                    // Only show duration selection for reservations
                    if rental.rentalType == .reservation {
                        durationSection
                    }
                    
                    if selectedDuration == .hourly {
                        hourlyRentalInfoSection
                    }
                    featuresSection
                    
                    // Error message if needed
                    if showPlanRequiredHint {
                        Text("Please select both a plan tier and duration to continue")
                            .font(.subheadline)
                            .foregroundColor(AppColors.error)
                            .padding(.vertical, 10)
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
            }
            
            if !isInformationOnly {
                bottomButton
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(AppColors.background)
        .fullScreenCover(isPresented: $showConfirmation) {
            if rental.rentalType == .reservation {
                // Create a new rental with the reservation date from the original rental
                let reservationRental = LockerRental(
                    id: UUID().uuidString,
                    shopName: rental.shopName,
                    size: rental.size,
                    rentalType: .reservation,
                    reservationDate: rental.reservationDate,
                    totalPrice: selectedTier.hourlyRate * 2.0, // 2x hourly rate for prepayment
                    plan: Plan(tier: selectedTier, duration: selectedDuration)
                )
                PaymentConfirmationView(rental: reservationRental, location: location)
                    .environmentObject(authViewModel)
            }
        }
        .fullScreenCover(isPresented: $showRentalSuccess) {
            RentalSuccessView(
                isCompletingRental: false,
                rental: rental,
                duration: nil,
                totalAmount: nil,
                hourlyRate: selectedTier.hourlyRate
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text(navigationTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Placeholder to balance header
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.clear)
            }
            .padding(.top, 12)
            
            if !isInformationOnly {
                lockerInfoSummary
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(AppColors.surface)
    }
    
    private var lockerInfoSummary: some View {
        VStack(spacing: 8) {
            Text(rental.shopName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 12) {
                Text("\(rental.size.rawValue) Locker")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.secondary.opacity(0.2))
                    .cornerRadius(12)
                
                Text("Step 2 of 2")
                    .font(.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(12)
            }
        }
    }
    
    private var planTierSection: some View {
        VStack(spacing: 16) {
            Text("Select Plan Tier")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(PlanTier.allCases) { tier in
                    planTierButton(for: tier)
                }
            }
        }
        .padding(.top, 24)
    }
    
    private func planTierButton(for tier: PlanTier) -> some View {
        Button(action: {
            withAnimation {
                selectedTier = tier
                showPlanRequiredHint = false
            }
        }) {
            VStack(spacing: 8) {
                Text(tier.rawValue)
                    .font(.headline)
                    .foregroundColor(tierTextColor(tier))
                
                Text(tier == .premium ? "Enhanced Experience" : "Basic Access")
                    .font(.caption)
                    .foregroundColor(selectedTier == tier ? AppColors.textPrimary.opacity(0.8) : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(tierBackgroundColor(tier))
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tierBorderColor(tier), lineWidth: 1)
            )
        }
    }
    
    private var durationSection: some View {
        VStack(spacing: 16) {
            Text("Select Duration")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Only show hourly option
            durationButton(for: .hourly)
        }
    }
    
    private func durationButton(for duration: PlanDuration) -> some View {
        Button(action: {
            withAnimation {
                selectedDuration = duration
                showPlanRequiredHint = false
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.rawValue)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(duration.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Only show hourly pricing
                VStack(alignment: .trailing, spacing: 4) {
                    Text("€\(String(format: "%.2f", selectedTier.hourlyRate))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.secondary)
                    Text("per hour")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        durationBorderColor(duration),
                        lineWidth: durationBorderWidth(duration)
                    )
            )
        }
    }
    
    private var hourlyRentalInfoSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(selectedTier == .premium ? AppColors.secondary : Color.blue)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pay-as-you-go Rental")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Your rental will start immediately and you'll only be charged for the time you use")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 5)
            
            // Rate info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Text("€\(String(format: "%.2f", selectedTier.hourlyRate))/hour")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTier == .premium ? AppColors.secondary : Color.blue)
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 5)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedTier.rawValue) Plan Features")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(selectedTier.features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(selectedTier == .premium ? AppColors.secondary : Color.blue)
                        .font(.system(size: 16))
                    
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: AppColors.background.opacity(0.3), radius: 5)
    }
    
    private var bottomButton: some View {
        VStack {
            Button(action: {
                if rental.rentalType == .reservation {
                    // For reservations, go to ConfirmationView
                    showConfirmation = true
                } else {
                    // For direct rentals, proceed as before
                    proceedWithRental()
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            .padding(.trailing, 8)
                    }
                    
                    Text(isProcessing ? "Processing..." : (rental.rentalType == .reservation ? "Proceed to Rent" : "Proceed to Rent"))
                        .fontWeight(.semibold)
                    
                    if !isProcessing {
                        Image(systemName: "key.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isProcessing ? AppColors.surfaceSecondary : AppColors.primary)
                .foregroundColor(Color.white)
                .cornerRadius(12)
                .shadow(color: AppColors.background.opacity(0.3), radius: 5)
            }
            .disabled(isProcessing)
        }
        .padding()
        .background(
            Rectangle()
                .fill(AppColors.surface)
                .shadow(color: AppColors.background.opacity(0.3), radius: 8, y: -4)
        )
    }
    
    private func proceedWithRental() {
        guard !isProcessing else { return }
        isProcessing = true
        
        guard let user = authViewModel.currentUser else {
            DispatchQueue.main.async {
                errorMessage = "Please log in to continue"
                showError = true
                isProcessing = false
            }
            return
        }
        
        // Create a plan object
        let plan = Plan(
            tier: selectedTier,
            duration: selectedDuration,
            totalHours: selectedDuration == .hourly ? 1 : 24
        )
        
        // Set up mock data for demo
        // This is a temporary solution to demonstrate the UI flow
        // In a real app, this would be replaced with actual Firebase data
        
        // Create a rental in Firestore
        let db = Firestore.firestore()
        let rentalId = UUID().uuidString
        let rentalRef = db.collection("rentals").document(rentalId)
        
        let rentalData: [String: Any] = [
            "id": rentalId,
            "userId": user.id,
            "locationId": location.id.uuidString,
            "locationName": location.name,
            "size": rental.size.rawValue,
            "status": "active",
            "startDate": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date()),
            "plan": [
                "tier": selectedTier.rawValue,
                "duration": selectedDuration.rawValue,
                "totalHours": selectedDuration == .hourly ? 1 : 24
            ] as [String: Any]
        ]
        
        rentalRef.setData(rentalData) { error in
            DispatchQueue.main.async { [self] in
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                } else {
                    // Update the locker availability
                    self.updateLockerAvailability(for: self.rental.size.rawValue, at: self.location.id.uuidString)
                    
                    // Post notification to refresh the locker map
                    NotificationCenter.default.post(name: Notification.Name("RefreshLockerMap"), object: nil)
                    
                    // Show success view
                    self.showRentalSuccess = true
                }
            }
        }
    }
    
    // Helper method to update locker availability
    private func updateLockerAvailability(for size: String, at locationId: String) {
        let db = Firestore.firestore()
        
        // Update the location document to decrement the available count
        db.collection("locations")
            .document(locationId)
            .updateData([
                "availableLockers.\(size.lowercased())": FieldValue.increment(Int64(-1))
            ]) { error in
                if let error = error {
                    print("Error updating locker availability: \(error.localizedDescription)")
                } else {
                    print("Successfully decremented available locker count for \(size)")
                }
            }
    }
}

#Preview {
    PlanSelectionView(isInformationOnly: true)
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
} 
