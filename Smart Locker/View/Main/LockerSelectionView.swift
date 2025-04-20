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
                    .foregroundColor(isSelected ? AppColors.primaryYellow : Color.gray)
                    .frame(height: 36)
                
                // Size name
                Text(size.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? AppColors.primaryBlack : .gray)
                
                // Dimensions
                Text(size.dimensions)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Price
                Text("$\(String(format: "%.2f", size.basePrice))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? AppColors.primaryYellow : AppColors.primaryBlack)
                    .padding(.top, 6)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primaryYellow : Color.gray.opacity(0.2), 
                            lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? AppColors.primaryYellow.opacity(0.3) : Color.black.opacity(0.05), 
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
    @State private var showPaymentConfirmation = false
    @State private var showSizeSelectionHint = false
    
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
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showPlansInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primaryYellow)
                    }
                }
                .padding(.top, 8)
                
                // Shop info
                VStack(spacing: 8) {
                    // Shop name & location
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColors.primaryYellow)
                            .font(.system(size: 20))
                        
                        Text(location.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Rental type badge
                HStack(spacing: 12) {
                    Text(rentalType == .instant ? "Direct Rent" : "Reservation")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(rentalType == .instant ? AppColors.primaryYellow.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(rentalType == .instant ? AppColors.primaryBlack : Color.blue)
                        .cornerRadius(12)
                    
                    Text("Step 1 of 2")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 8)
            
            // Content - Locker Selection
            ScrollView {
                VStack(spacing: 24) {
                    // Title with availability count
                    HStack {
                        Text("Available Sizes")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("30 lockers of each size available")
                            .font(.caption)
                            .foregroundColor(.gray)
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
                            .foregroundColor(.red)
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
                    .background(selectedSize != nil ? AppColors.primaryBlack : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedSize == nil)
                
                // Secondary action button
                Button(action: {
                    if let size = selectedSize {
                        withAnimation {
                            showPaymentConfirmation = true
                        }
                    } else {
                        withAnimation {
                            showSizeSelectionHint = true
                        }
                    }
                }) {
                    HStack {
                        Text("Skip Plan & Proceed to Payment")
                            .fontWeight(.medium)
                        
                        Image(systemName: "creditcard")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedSize != nil ? AppColors.primaryYellow : Color.gray.opacity(0.5))
                    .foregroundColor(AppColors.primaryBlack)
                    .cornerRadius(12)
                }
                .disabled(selectedSize == nil)
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color(UIColor.systemBackground))
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
        .fullScreenCover(isPresented: $showPaymentConfirmation) {
            if let size = selectedSize {
                LockerConfirmationView(
                    rental: LockerRental(
                        id: UUID().uuidString,
                        shopName: location.name,
                        size: size,
                        rentalType: rentalType,
                        reservationDate: reservationDates?.first,
                        plan: Plan(tier: .standard, duration: .daily) // Default plan
                    ),
                    location: location
                )
                .environmentObject(AuthViewModel.shared ?? AuthViewModel())
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
