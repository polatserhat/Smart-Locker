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
    
    private var basePrice: Double {
        return rental.plan?.price ?? rental.size.basePrice
    }
    
    private var totalPrice: Double {
        return rental.totalPrice ?? (basePrice * 1.1)
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
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text("Confirm Details")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Location and Size Summary
            VStack(spacing: 20) {
                // Location Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(rental.shopName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(AppColors.divider)
                
                // Locker Size Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Locker Size")
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Text(rental.size.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("(\(rental.size.dimensions))")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Plan Info
                if let plan = rental.plan {
                    Divider()
                        .background(AppColors.divider)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Plan")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            Text(plan.tier.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(plan.tier == .premium ? AppColors.secondary : Color.blue)
                            
                            Text("- \(plan.duration.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if rental.rentalType == .reservation {
                    Divider()
                        .background(AppColors.divider)
                    
                    // Reservation Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reservation Date")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if let date = rental.reservationDate {
                            Text(date.formatted(.dateTime.day().month().year().hour().minute()))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 10)
            
            // Pricing Details
            VStack(spacing: 16) {
                Text("Pricing Details")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Base Price")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("€\(String(format: "%.2f", basePrice))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    HStack {
                        Text("Tax (10%)")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("€\(String(format: "%.2f", basePrice * 0.1))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    Divider()
                        .background(AppColors.divider)
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("€\(String(format: "%.2f", totalPrice))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.secondary)
                    }
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                .shadow(color: AppColors.background.opacity(0.3), radius: 10)
            }
            
            Spacer()
            
            // Terms and Conditions
            VStack(spacing: 8) {
                Text("By proceeding, you agree to our")
                    .font(.footnote)
                    .foregroundColor(AppColors.textSecondary)
                
                Button(action: {
                    // Show Terms and Conditions
                }) {
                    Text("Terms and Conditions")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.secondary)
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
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                        .frame(height: 24)
                } else {
                    HStack(spacing: 16) {
                        Image(systemName: rental.rentalType == .reservation ? "calendar.badge.checkmark" : "creditcard.fill")
                            .font(.system(size: 20))
                        
                        Text(rental.rentalType == .reservation ? "Confirm Reservation" : "Proceed to Payment")
                            .fontWeight(.semibold)
                        
                        if !isProcessing {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16))
                        }
                    }
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.primary, AppColors.secondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: AppColors.background.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .disabled(isProcessing)
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
        .background(AppColors.background)
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
            reservationDate: nil as Date?,
            startTime: nil,
            endTime: nil,
            status: .pending,
            totalPrice: 15.0,
            plan: Plan(tier: .standard, duration: .daily, totalHours: 24)
        ),
        location: LockerLocation(
            name: "Airport Terminal 1",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Airport Blvd, San Francisco, CA 94128"
        )
    )
    .environmentObject(AuthViewModel())
    .preferredColorScheme(.dark)
} 