import SwiftUI

struct LockerSizeCard: View {
    let size: LockerSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Size Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primaryYellow.opacity(0.2) : AppColors.secondaryGray)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.primaryBlack : .gray)
                }
                
                // Size Details
                VStack(spacing: 4) {
                    Text(size.rawValue)
                        .font(.headline)
                    Text(size.dimensions)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", size.basePrice))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlack)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primaryYellow : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10)
        }
    }
}

struct LockerSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSize: LockerSize?
    @State private var showPlanSelection = false
    @State private var showPlansInfo = false
    @State private var showSizeSelectionHint = false
    
    let location: LockerLocation
    let rentalType: RentalType
    
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
                
                Text("Select Your Locker Size")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Location Summary
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.headline)
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    Text(rentalType == .instant ? "Direct Rent" : "Reservation")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(rentalType == .instant ? AppColors.primaryYellow : Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    // Step indicator
                    Text("Step 1 of 2")
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
            
            // View Plans Button
            Button(action: {
                showPlansInfo = true
            }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.primaryYellow)
                    Text("View Available Plans")
                        .foregroundColor(AppColors.primaryBlack)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Locker Size Selection
            VStack(spacing: 16) {
                Text("Available Sizes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(LockerSize.allCases, id: \.self) { size in
                        LockerSizeCard(
                            size: size,
                            isSelected: selectedSize == size
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSize = size
                                showSizeSelectionHint = false
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Selection Hint
            if showSizeSelectionHint {
                Text("Please select a locker size to continue")
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // CTA Button
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
                Text("Continue to Plan Selection")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedSize != nil ? AppColors.primaryBlack : Color.gray)
                    .cornerRadius(12)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showPlanSelection) {
            if let size = selectedSize {
                PlanSelectionView(
                    rental: LockerRental(
                        id: UUID().uuidString,
                        shopName: location.name,
                        size: size,
                        rentalType: rentalType,
                        reservationDate: nil
                    ),
                    location: location
                )
                .transition(.move(edge: .trailing))
            }
        }
        .fullScreenCover(isPresented: $showPlansInfo) {
            PlanSelectionView(isInformationOnly: true)
                .transition(.opacity)
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
} 
