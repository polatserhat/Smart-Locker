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
    @State private var showConfirmation = false
    
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
                
                Text(rentalType == .instant ? "Direct Rent" : "Reservation")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(rentalType == .instant ? AppColors.primaryYellow : Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            
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
                            selectedSize = size
                        }
                    }
                }
            }
            
            Spacer()
            
            // CTA Button
            Button(action: {
                if let size = selectedSize {
                    showConfirmation = true
                }
            }) {
                Text("Confirm Selection")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedSize != nil ? AppColors.primaryBlack : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(selectedSize == nil)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showConfirmation) {
            if let size = selectedSize {
                LockerConfirmationView(
                    rental: LockerRental(
                        id: UUID().uuidString,
                        shopName: location.name,
                        size: size,
                        rentalType: rentalType,
                        reservationDate: nil
                    ),
                    location: location
                )
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
} 
