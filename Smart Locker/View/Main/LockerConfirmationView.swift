import SwiftUI
import MapKit

struct LockerConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showPaymentView = false
    @State private var error: String?
    @State private var showError = false
    @State private var isProcessing = false
    
    let rental: LockerRental
    let location: LockerLocation
    
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
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
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
                if rental.rentalType == .reservation {
                    createReservation()
                } else {
                    showPaymentView = true
                }
            }) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(rental.rentalType == .reservation ? "Confirm Reservation" : "Proceed to Payment")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryBlack)
                        .cornerRadius(12)
                }
            }
            .disabled(isProcessing)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showPaymentView) {
            PaymentView(rental: rental, location: location)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "An error occurred")
        }
    }
    
    private func createReservation() {
        guard let userId = authViewModel.currentUser?.id else {
            error = "User not logged in"
            showError = true
            return
        }
        
        guard let reservationDate = rental.reservationDate else {
            error = "No reservation date selected"
            showError = true
            return
        }
        
        isProcessing = true
        
        FirestoreService.shared.createReservation(
            userId: userId,
            location: location,
            size: rental.size,
            dates: [reservationDate]
        ) { result in
            isProcessing = false
            
            switch result {
            case .success:
                showPaymentView = true
            case .failure(let error):
                self.error = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    LockerConfirmationView(
        rental: LockerRental(
            id: UUID().uuidString,
            shopName: "Airport Terminal 1",
            size: LockerSize.medium,
            rentalType: RentalType.instant,
            reservationDate: nil as Date?
        ),
        location: LockerLocation(
            name: "Airport Terminal 1",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Airport Blvd, San Francisco, CA 94128"
        )
    )
    .environmentObject(AuthViewModel())
} 