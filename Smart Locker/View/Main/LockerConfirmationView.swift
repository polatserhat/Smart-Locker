import SwiftUI

struct LockerConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPaymentView = false
    
    let rental: LockerRental
    
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
                
                Text("Confirm Details")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Location and Size Summary
            VStack(spacing: 20) {
                // Location Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(rental.shopName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Locker Size Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Locker Size")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(rental.size.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("(\(rental.size.dimensions))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if rental.rentalType == .reservation {
                    Divider()
                    
                    // Reservation Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reservation Date")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if let date = rental.reservationDate {
                            Text(date.formatted(date: .long, time: .shortened))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            
            // Pricing Details
            VStack(spacing: 16) {
                Text("Pricing Details")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Base Price")
                        Spacer()
                        Text("$\(String(format: "%.2f", rental.size.basePrice))")
                    }
                    
                    HStack {
                        Text("Tax (10%)")
                        Spacer()
                        Text("$\(String(format: "%.2f", rental.size.basePrice * 0.1))")
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$\(String(format: "%.2f", rental.size.basePrice * 1.1))")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
            }
            
            Spacer()
            
            // Terms and Conditions
            VStack(spacing: 8) {
                Text("By proceeding, you agree to our")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button(action: {
                    // Show Terms and Conditions
                }) {
                    Text("Terms and Conditions")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryBlack)
                        .underline()
                }
            }
            
            // CTA Button
            Button(action: {
                showPaymentView = true
            }) {
                Text("Proceed to Payment")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primaryBlack)
                    .cornerRadius(12)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showPaymentView) {
            PaymentView(rental: rental)
        }
    }
}

#Preview {
    LockerConfirmationView(rental: LockerRental(
        id: UUID().uuidString,
        shopName: "Airport Terminal 1",
        size: LockerSize.medium,
        rentalType: RentalType.instant,
        reservationDate: nil as Date?
    ))
} 