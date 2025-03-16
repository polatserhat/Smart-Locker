import SwiftUI

struct PaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let rental: LockerRental
    
    var body: some View {
        VStack(spacing: 32) {
            // Success Animation
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(1)
                    .onAppear {
                        withAnimation(.spring(dampingFraction: 0.6)) {
                            // Add scale animation
                        }
                    }
                
                Text("Your Rental is Confirmed!")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 60)
            
            // Reservation Details
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reservation Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "mappin.circle.fill", title: "Locker Shop", value: rental.shopName)
                        DetailRow(icon: "cube.fill", title: "Selected Size", value: "\(rental.size.rawValue) (\(rental.size.dimensions))")
                        DetailRow(icon: "clock.fill", title: "Duration", value: "24 Hours")
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                
                // QR Code (Mocked)
                VStack(spacing: 12) {
                    Text("Access Code")
                        .font(.headline)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 120))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    Text("Scan this code at the locker")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Next Steps
            VStack(spacing: 12) {
                Button(action: {
                    // Navigate to reservations
                }) {
                    Text("View My Reservations")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Return to home and dismiss all sheets
                    dismiss()
                }) {
                    Text("Return to Home")
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    PaymentConfirmationView(rental: LockerRental(
        id: "1",
        shopName: "Smart Locker Shop - A-103",
        size: .medium,
        rentalType: .instant,
        reservationDate: nil
    ))
} 
