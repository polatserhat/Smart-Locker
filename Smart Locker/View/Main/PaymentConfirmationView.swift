import SwiftUI
import MapKit

struct PaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDirectionsSheet = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    let rental: LockerRental
    let location: LockerLocation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                .padding(.top, 32)
                
                // Reservation Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reservation Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "mappin.circle.fill", title: "Locker Shop", value: rental.shopName)
                        DetailRow(icon: "cube.fill", title: "Selected Size", value: "\(rental.size.rawValue) (\(rental.size.dimensions))")
                        
                        if let plan = rental.plan {
                            DetailRow(icon: "star.fill", title: "Selected Plan", value: "\(plan.tier.rawValue) - \(plan.duration.rawValue)")
                            DetailRow(icon: "clock.fill", title: "Duration", value: getDurationString(for: plan))
                            DetailRow(icon: "dollarsign.circle.fill", title: "Total Price", value: "$\(String(format: "%.2f", rental.totalPrice ?? plan.price))")
                        } else {
                            DetailRow(icon: "clock.fill", title: "Duration", value: "24 Hours")
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                
                // QR Code Section
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
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
        }
        
        // Fixed Bottom Action Buttons
        VStack(spacing: 16) {
            // Get Directions Button
            Button(action: {
                showingDirectionsSheet = true
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Get Directions")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primaryYellow)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                // View Reservations Button
                Button(action: {
                    // Navigate to reservations
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("My Reservations")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryBlack)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                }
                
                // Return Home Button
                Button(action: {
                    // First dismiss this view
                    presentationMode.wrappedValue.dismiss()
                    
                    // Then dismiss any other presented sheets
                    dismiss()
                    
                    // Finally trigger navigation to home after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        authViewModel.navigateToHome = true
                    }
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryYellow)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
        )
        .confirmationDialog(
            "Get Directions",
            isPresented: $showingDirectionsSheet,
            titleVisibility: .visible
        ) {
            Button("Open in Apple Maps") {
                location.openInMaps()
            }
            
            Button("Open in Google Maps") {
                location.openInGoogleMaps()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose your preferred navigation app")
        }
    }
    
    private func getDurationString(for plan: Plan) -> String {
        switch plan.duration {
        case .hourly:
            return "\(plan.totalHours) hour\(plan.totalHours > 1 ? "s" : "")"
        case .daily:
            return "\(plan.totalHours / 24) day\(plan.totalHours > 24 ? "s" : "")"
        case .weekly:
            return "\(plan.totalHours / 24 / 7) week\(plan.totalHours > (24 * 7) ? "s" : "")"
        case .monthly:
            return "\(plan.totalHours / 24 / 30) month\(plan.totalHours > (24 * 30) ? "s" : "")"
        }
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
    PaymentConfirmationView(
        rental: LockerRental(
            id: "1",
            shopName: "Smart Locker Shop - A-103",
            size: .medium,
            rentalType: .instant,
            reservationDate: nil,
            plan: Plan(tier: .premium, duration: .daily)
        ),
        location: LockerLocation(
            name: "Smart Locker Shop - A-103",
            coordinate: CLLocationCoordinate2D(latitude: 37.7697, longitude: -122.4269),
            address: "789 Howard St, San Francisco, CA 94103"
        )
    )
    .environmentObject(AuthViewModel())
} 
