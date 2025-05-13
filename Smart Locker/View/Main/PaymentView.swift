import SwiftUI
import MapKit

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var paymentDetails = PaymentDetails()
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var error: String?
    @State private var showError = false
    
    let rental: LockerRental
    let location: LockerLocation
    
    // Check if this is a completing an existing rental
    private var isCompletingExistingRental: Bool {
        return rental.startTime != nil && rental.status == .active
    }
    
    let paymentMethods = [
        PaymentMethod(name: "Credit/Debit Card", icon: "creditcard.fill", isSelected: true),
        PaymentMethod(name: "Apple Pay", icon: "apple.logo", isSelected: false),
        PaymentMethod(name: "Account Balance", icon: "wallet.pass.fill", isSelected: false)
    ]
    
    private var duration: String {
        if isCompletingExistingRental, let startTime = rental.startTime {
            // For existing rentals, calculate actual duration
            let components = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: Date())
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0
            
            return "\(hours) hour\(hours > 1 ? "s" : "") \(minutes) minute\(minutes > 1 ? "s" : "")"
        } else if let plan = rental.plan {
            // For new rentals with a plan
            if let totalHours = plan.totalHours {
                switch plan.duration {
                case .hourly: return "\(totalHours) Hour\(totalHours > 1 ? "s" : "")"
                case .daily: return "1 Day"
                }
            } else {
                return plan.duration.rawValue
            }
        } else {
            return "24 Hours"
        }
    }
    
    private var totalPrice: Double {
        // If completing an existing rental, use the precalculated price
        if isCompletingExistingRental {
            return rental.totalPrice ?? 0
        }
        // For new rentals, calculate based on plan
        return rental.totalPrice ?? (rental.plan?.price ?? rental.size.basePrice) * 1.1
    }
    
    private var checkoutTitle: String {
        return isCompletingExistingRental ? "Complete Payment" : "Secure Checkout"
    }
    
    private var checkoutSubtitle: String {
        return isCompletingExistingRental ? "Complete your rental payment" : "Complete your rental payment"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(checkoutTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(checkoutSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Order Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Summary")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            OrderDetailRow(title: "Locker Shop", value: rental.shopName)
                            OrderDetailRow(title: "Selected Size", value: "\(rental.size.rawValue) (\(rental.size.dimensions))")
                            
                            if !isCompletingExistingRental, let plan = rental.plan {
                                OrderDetailRow(title: "Selected Plan", value: "\(plan.tier.rawValue) - \(plan.duration.rawValue)")
                            }
                            
                            OrderDetailRow(title: isCompletingExistingRental ? "Usage Time" : "Duration", value: duration)
                            OrderDetailRow(title: "Total Amount", value: "$\(String(format: "%.2f", totalPrice))", isTotal: true)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    // Payment Methods
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Method")
                            .font(.headline)
                        
                        ForEach(paymentMethods) { method in
                            PaymentMethodRow(method: method, isSelected: selectedPaymentMethod?.id == method.id) {
                                selectedPaymentMethod = method
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    // Credit Card Form
                    if selectedPaymentMethod?.name == "Credit/Debit Card" {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Card Details")
                                .font(.headline)
                            
                            VStack(spacing: 16) {
                                InputField(title: "CARDHOLDER NAME", text: $paymentDetails.cardholderName)
                                InputField(title: "CARD NUMBER", text: $paymentDetails.cardNumber)
                                
                                HStack(spacing: 12) {
                                    InputField(title: "EXPIRY DATE", text: $paymentDetails.expiryDate)
                                    InputField(title: "CVV", text: $paymentDetails.cvv, isSecure: true)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                    }
                }
                .padding(.vertical)
            }
            
            // CTA Buttons
            VStack(spacing: 16) {
                Button(action: {
                    processPayment()
                }) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 24)
                    } else {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 20))
                            
                            Text("Complete Payment")
                                .fontWeight(.semibold)
                            
                            if !isProcessing {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16))
                            }
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
                .disabled(isProcessing)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Go Back")
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)  // Increased bottom padding for easier access
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentConfirmationView(rental: rental, location: location)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "An error occurred")
        }
        .onAppear {
            print("PaymentView appeared with rental: \(rental.id), startTime: \(String(describing: rental.startTime)), totalPrice: \(String(describing: rental.totalPrice))")
        }
    }
    
    private func processPayment() {
        guard let userId = authViewModel.currentUser?.id else {
            error = "User not logged in"
            showError = true
            return
        }
        
        isProcessing = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            // Show confirmation screen after payment is processed
            showConfirmation = true
        }
    }
}

struct OrderDetailRow: View {
    let title: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .subheadline)
                .foregroundColor(isTotal ? .black : .gray)
            Spacer()
            Text(value)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.icon)
                    .font(.system(size: 20))
                Text(method.name)
                    .font(.subheadline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    PaymentView(
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
} 
