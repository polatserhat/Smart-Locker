import SwiftUI
import MapKit

struct PlanSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTier: PlanTier = .standard
    @State private var selectedDuration: PlanDuration = .hourly
    @State private var showConfirmation = false
    @State private var showPlanRequiredHint = false
    
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
            ? (tier == .premium ? AppColors.primaryYellow : Color.blue)
            : Color.white
        }
    }
    
    private var tierTextColor: (PlanTier) -> Color {
        { tier in
            selectedTier == tier ? .white : .primary
        }
    }
    
    private var tierBorderColor: (PlanTier) -> Color {
        { tier in
            selectedTier == tier
            ? Color.clear
            : (tier == .premium ? AppColors.primaryYellow : Color.blue).opacity(0.3)
        }
    }
    
    private var durationBorderColor: (PlanDuration) -> Color {
        { duration in
            selectedDuration == duration
            ? (selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
            : Color.gray.opacity(0.2)
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
                .fill(Color.gray.opacity(0.1))
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
                    } else if selectedDuration == .daily {
                        dailyRentalInfoSection
                    }
                    featuresSection
                    
                    // Error message if needed
                    if showPlanRequiredHint {
                        Text("Please select both a plan tier and duration to continue")
                            .font(.subheadline)
                            .foregroundColor(.red)
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
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showConfirmation) {
            let plan = Plan(
                tier: selectedTier,
                duration: selectedDuration,
                startTime: Date(),
                totalHours: selectedDuration == .hourly ? 1 : 24
            )
            let updatedRental = LockerRental(
                id: rental.id,
                shopName: rental.shopName,
                size: rental.size,
                rentalType: rental.rentalType,
                reservationDate: rental.reservationDate,
                startTime: Date(),
                endTime: selectedDuration == .hourly ? 
                    Calendar.current.date(byAdding: .hour, value: 1, to: Date()) : 
                    Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                status: .active,
                totalPrice: totalPrice,
                plan: plan
            )
            
            if rental.rentalType == .instant {
                // For hourly rentals, go straight to the rental confirmation without payment
                PaymentConfirmationView(rental: updatedRental, location: location)
                    .environmentObject(AuthViewModel.shared ?? authViewModel)
            } else {
                // For other durations, go to payment view
                LockerConfirmationView(rental: updatedRental, location: location)
                    .environmentObject(AuthViewModel.shared ?? authViewModel)
            }
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
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text(navigationTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                
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
    }
    
    private var lockerInfoSummary: some View {
        VStack(spacing: 8) {
            Text(rental.shopName)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                Text("\(rental.size.rawValue) Locker")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primaryYellow.opacity(0.2))
                    .cornerRadius(12)
                
                Text("Step 2 of 2")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    private var planTierSection: some View {
        VStack(spacing: 16) {
            Text("Select Plan Tier")
                .font(.headline)
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
                
                Text(tier == .premium ? "Enhanced Security" : "Basic Access")
                    .font(.caption)
                    .foregroundColor(selectedTier == tier ? .white.opacity(0.8) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(tierBackgroundColor(tier))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
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
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(PlanDuration.allCases) { duration in
                    durationButton(for: duration)
                }
            }
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
                    
                    Text(duration.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                durationPriceView(for: duration)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        durationBorderColor(duration),
                        lineWidth: durationBorderWidth(duration)
                    )
            )
        }
    }
    
    private func durationPriceView(for duration: PlanDuration) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if duration == .hourly {
                Text("$\(String(format: "%.2f", selectedTier.hourlyRate))")
                    .font(.headline)
                    .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                Text("per hour")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("$\(String(format: "%.2f", duration.getPrice(for: selectedTier)))")
                    .font(.headline)
                    .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                
                Text("per day")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var hourlyRentalInfoSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pay-as-you-go Rental")
                        .font(.headline)
                    Text("Your rental will start immediately and you'll only be charged for the time you use")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
            
            // Rate info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", selectedTier.hourlyRate))/hour")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
        }
    }
    
    private var dailyRentalInfoSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("24-Hour Rental Period")
                        .font(.headline)
                    Text("Your rental will start immediately and end after 24 hours")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
            
            totalPriceView
        }
    }
    
    private var totalPriceView: some View {
        HStack {
            Text("Total Price:")
                .font(.headline)
            Spacer()
            Text("$\(String(format: "%.2f", totalPrice))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedTier.rawValue) Plan Features")
                .font(.headline)
            
            ForEach(selectedTier.features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                        .font(.system(size: 16))
                    
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    private var bottomButton: some View {
        VStack {
            Button(action: {
                withAnimation {
                    showConfirmation = true
                }
            }) {
                HStack {
                    Text("Proceed to Payment")
                        .fontWeight(.semibold)
                    
                    Image(systemName: "creditcard.fill")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primaryBlack)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
        )
    }
}

#Preview {
    PlanSelectionView(isInformationOnly: true)
        .environmentObject(AuthViewModel())
} 
