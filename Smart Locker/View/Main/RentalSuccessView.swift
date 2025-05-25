import SwiftUI

struct RentalSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCompletingRental: Bool
    let rental: LockerRental?
    let duration: String?
    let totalAmount: Double?
    let hourlyRate: Double?
    
    init(isCompletingRental: Bool = false, rental: LockerRental? = nil, duration: String? = nil, totalAmount: Double? = nil, hourlyRate: Double? = nil) {
        self.isCompletingRental = isCompletingRental
        self.rental = rental
        self.duration = duration
        self.totalAmount = totalAmount
        self.hourlyRate = hourlyRate
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.secondary)
                .padding(.top, 40)
            
            // Title
            Text(isCompletingRental ? "Rental Ended!" : "Rental Started!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            // Message
            Text(isCompletingRental ? 
                "Your rental has been completed successfully. Here's your receipt." :
                "Your locker is now ready to use. You can find your active rental on the home screen.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 32)
            
            if let rental = rental {
                // Rental Details Card
                VStack(spacing: 16) {
                    if isCompletingRental {
                        Text("Receipt")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 8)
                    } else {
                        Text("Rental Details")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 8)
                    }
                    
                    VStack(spacing: 12) {
                        // Location
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Text(rental.shopName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        // Locker Details
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Locker Size")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(rental.size.rawValue)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Spacer()
                            
                            if let rate = hourlyRate {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Rate")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                    Text("$\(String(format: "%.2f", rate))/hour")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.secondary)
                                }
                            }
                        }
                        
                        if isCompletingRental {
                            Divider()
                            
                            // Duration
                            if let duration = duration {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Duration")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                    Text(duration)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Total Amount
                            if let amount = totalAmount {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Amount")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("$\(String(format: "%.2f", amount))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding(24)
                .background(AppColors.surface)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            
            Spacer()
            
            // Return Home Button
            Button(action: {
                // Post notification to dismiss all views and return to home
                NotificationCenter.default.post(name: Notification.Name("DismissToRoot"), object: nil)
            }) {
                Text("RETURN TO HOME")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.secondary)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
    }
}

#Preview {
    Group {
        // Preview for Rental Start
        RentalSuccessView(
            isCompletingRental: false,
            rental: LockerRental(
                id: "123",
                shopName: "Smart Locker Shop - A-001",
                size: .medium,
                rentalType: .instant,
                startTime: nil
            ),
            hourlyRate: 0.20
        )
        
        // Preview for Rental End
        RentalSuccessView(
            isCompletingRental: true,
            rental: LockerRental(
                id: "123",
                shopName: "Smart Locker Shop - A-001",
                size: .medium,
                rentalType: .instant,
                startTime: Date().addingTimeInterval(-3600)
            ),
            duration: "1 hour",
            totalAmount: 15.99,
            hourlyRate: 0.20
        )
    }
} 