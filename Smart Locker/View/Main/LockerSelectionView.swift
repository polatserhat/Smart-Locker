import SwiftUI

struct LockerSizeCard: View {
    let size: LockerSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Size Icon
                Image(systemName: size == .small ? "briefcase.fill" : 
                                (size == .medium ? "cube.box.fill" : "shippingbox.fill"))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppColors.secondary : AppColors.textSecondary)
                    .frame(height: 36)
                
                // Size name
                Text(size.rawValue)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                // Dimensions
                Text(size.dimensions)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                // Price
                VStack(spacing: 4) {
                    Text("Size Fee")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("€\(String(format: "%.2f", size.sizeFee))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.secondary : AppColors.primary)
                )
                .padding(.top, 6)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.secondary : AppColors.divider, lineWidth: 1)
            )
            .shadow(color: isSelected ? AppColors.secondary.opacity(0.3) : Color.black.opacity(0.05), 
                    radius: isSelected ? 8 : 4)
        }
    }
}

struct LockerSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedSize: LockerSize?
    @State private var showPlanSelection = false
    @State private var showPlansInfo = false
    @State private var showSizeSelectionHint = false
    @State private var showPaymentForReservation = false
    @State private var reservationRental: LockerRental?
    
    let location: LockerLocation
    let rentalType: RentalType
    var reservationDates: Set<Date>?
    
    init(location: LockerLocation, rentalType: RentalType, reservationDates: Set<Date>? = nil) {
        self.location = location
        self.rentalType = rentalType
        self.reservationDates = reservationDates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
                    
                    Button(action: {
                        showPlansInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondary)
                    }
                }
                .padding(.top, 8)
                
                // Shop info
                VStack(spacing: 8) {
                    // Shop name & location
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColors.textPrimary)
                            .font(.system(size: 20))
                        
                        Text(location.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Rental type badge
                HStack(spacing: 12) {
                    Text(rentalType == .instant ? "Direct Rent" : "Reservation")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(rentalType == .instant ? AppColors.secondary.opacity(0.8) : Color.blue.opacity(0.2))
                        .foregroundColor(rentalType == .instant ? Color.white : Color.blue)
                        .cornerRadius(12)
                    
                    Text("Step 1 of 2")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 8)
            
            // Content - Locker Selection
            ScrollView {
                VStack(spacing: 24) {
                    // Title with availability count
                    HStack {
                        Text("Available Sizes")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text("30 lockers of each size available")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 24)
                    
                    // Locker Size Cards - Grid Layout
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(LockerSize.allCases, id: \.self) { size in
                            LockerSizeCard(
                                size: size,
                                isSelected: selectedSize == size
                            ) {
                                withAnimation {
                                    selectedSize = size
                                    showSizeSelectionHint = false
                                }
                            }
                        }
                    }
                    
                    // Error message if needed
                    if showSizeSelectionHint {
                        Text("Please select a locker size to continue")
                            .font(.subheadline)
                            .foregroundColor(AppColors.error)
                            .padding(.vertical, 10)
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
            }
            
            // Bottom navigation/action buttons
            VStack(spacing: 12) {
                // Primary action button
                Button(action: {
                    if let size = selectedSize {
                        withAnimation {
                            showPlanSelection = true
                        }
                    } else {
                        withAnimation {
                            showSizeSelectionHint = true
                        }
                    }
                }) {
                    HStack {
                        Text("Proceed to Plan Selection")
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedSize != nil ? AppColors.primary : Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(12)
                }
                .disabled(selectedSize == nil)
            }
            .padding()
            .background(
                Rectangle()
                    .fill(AppColors.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(AppColors.background)
        .fullScreenCover(isPresented: $showPlanSelection) {
            if let size = selectedSize {
                PlanSelectionView(
                    rental: LockerRental(
                        id: UUID().uuidString,
                        shopName: location.name,
                        size: size,
                        rentalType: rentalType,
                        reservationDate: reservationDates?.first
                    ),
                    location: location
                )
                .environmentObject(AuthViewModel.shared ?? AuthViewModel())
            }
        }
        .fullScreenCover(isPresented: $showPlansInfo) {
            PlanSelectionView(isInformationOnly: true)
                .environmentObject(AuthViewModel.shared ?? AuthViewModel())
        }
        .fullScreenCover(isPresented: $showPaymentForReservation) {
            if let rental = reservationRental {
                PaymentView(rental: rental, location: location)
                    .environmentObject(AuthViewModel.shared ?? AuthViewModel())
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaymentForReservation"))) { notification in
            if let rental = notification.object as? LockerRental {
                reservationRental = rental
                showPaymentForReservation = true
            }
        }
    }
}

extension LockerSize: CaseIterable {
    static var allCases: [LockerSize] = [.small, .medium, .large]
}

#Preview {
    LockerSelectionView(
        location: LockerLocation.sampleLocations[0],
        rentalType: .instant
    )
    .environmentObject(AuthViewModel.shared ?? AuthViewModel())
} 
