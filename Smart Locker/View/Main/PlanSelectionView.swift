import SwiftUI
import MapKit

struct PlanSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTier: PlanTier = .standard
    @State private var selectedDuration: PlanDuration = .daily
    @State private var showConfirmation = false
    @State private var showPlanRequiredHint = false
    
    let rental: LockerRental
    let location: LockerLocation
    let isInformationOnly: Bool
    
    init(rental: LockerRental? = nil, location: LockerLocation? = nil, isInformationOnly: Bool = false) {
        if let rental = rental {
            self.rental = rental
        } else {
            self.rental = LockerRental(
                id: "",
                shopName: "",
                size: .medium,
                rentalType: .instant,
                reservationDate: nil
            )
        }

        if let location = location {
            self.location = location
        } else {
            self.location = LockerLocation(
                name: "",
                coordinate: .init(latitude: 0, longitude: 0),
                address: ""
            )
        }

        self.isInformationOnly = isInformationOnly
    }
    
    // Helper method to create the confirmation view
    @ViewBuilder
    private func createConfirmationView() -> some View {
        if !isInformationOnly {
            let plan = Plan(tier: selectedTier, duration: selectedDuration)
            let updatedRental = LockerRental(
                id: rental.id,
                shopName: rental.shopName,
                size: rental.size,
                rentalType: rental.rentalType,
                reservationDate: rental.reservationDate,
                totalPrice: plan.price,
                plan: plan
            )
            LockerConfirmationView(rental: updatedRental, location: location)
                .transition(.move(edge: .trailing))
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.primaryBlack)
                }
                
                Spacer()
                
                Text(isInformationOnly ? "Available Plans" : "Select a Plan")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.top, 20)
            
            if !isInformationOnly {
                // Rental Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(rental.shopName)
                        .font(.headline)
                    
                    HStack {
                        Text("\(rental.size.rawValue) Locker")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.primaryYellow.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text("Step 2 of 2")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
            }
            
            // Plan Tier Selection
            VStack(spacing: 16) {
                Text("Plan Tier")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    ForEach(PlanTier.allCases) { tier in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTier = tier
                                showPlanRequiredHint = false
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tier.rawValue)
                                    .font(.headline)
                                    .foregroundColor(selectedTier == tier ? .white : .primary)
                                
                                Text(tier == .premium ? "Enhanced Security" : "Basic Access")
                                    .font(.caption)
                                    .foregroundColor(selectedTier == tier ? .white.opacity(0.8) : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedTier == tier
                                ? (tier == .premium ? AppColors.primaryYellow : Color.blue)
                                : Color.white
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedTier == tier 
                                        ? Color.clear 
                                        : (tier == .premium ? AppColors.primaryYellow : Color.blue).opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
            }
            
            // Duration Selection
            VStack(spacing: 16) {
                Text("Duration")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(PlanDuration.allCases) { duration in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("$\(String(format: "%.2f", duration.getPrice(for: selectedTier)))")
                                        .font(.headline)
                                        .foregroundColor(selectedTier == .premium ? AppColors.primaryYellow : Color.blue)
                                    
                                    if duration != .hourly {
                                        Text(duration == .daily ? "per day" : (duration == .weekly ? "per week" : "per month"))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedDuration == duration 
                                        ? (selectedTier == .premium ? AppColors.primaryYellow : Color.blue) 
                                        : Color.gray.opacity(0.2),
                                        lineWidth: selectedDuration == duration ? 2 : 1
                                    )
                            )
                        }
                    }
                }
            }
            
            // Features List
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
            
            Spacer()
            
            // Selection Hint
            if showPlanRequiredHint {
                Text("Please select both a plan tier and duration to continue")
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // CTA Button
            if !isInformationOnly {
                Button(action: {
                    withAnimation {
                        showConfirmation = true
                    }
                }) {
                    Text("Continue to Confirmation")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryBlack)
                        .cornerRadius(12)
                }
                .padding(.bottom, 30)
            }
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showConfirmation) {
            createConfirmationView()
        }
    }
}

#Preview {
    PlanSelectionView(isInformationOnly: true)
        .environmentObject(AuthViewModel())
} 
