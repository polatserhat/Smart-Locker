import SwiftUI
import MapKit

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var paymentDetails = PaymentDetails()
    @State private var selectedPaymentMethod: PaymentMethod?
    
    let rental: LockerRental
    let location: LockerLocation
    
    let paymentMethods = [
        PaymentMethod(name: "Credit/Debit Card", icon: "creditcard.fill", isSelected: true),
        PaymentMethod(name: "Apple Pay", icon: "apple.logo", isSelected: false),
        PaymentMethod(name: "Account Balance", icon: "wallet.pass.fill", isSelected: false)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Secure Checkout")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Complete your rental payment")
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
                            OrderDetailRow(title: "Duration", value: "24 Hours")
                            OrderDetailRow(title: "Total Amount", value: "$\(String(format: "%.2f", rental.totalPrice ?? 0.00))", isTotal: true)

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
            VStack(spacing: 12) {
                Button(action: {
                    processPayment()
                }) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Confirm & Pay")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isProcessing)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Go Back")
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentConfirmationView(rental: rental, location: location)
        }
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
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
            id: "1",
            shopName: "Smart Locker Shop - A-103",
            size: .medium,
            rentalType: .instant,
            reservationDate: nil
        ),
        location: LockerLocation(
            name: "Smart Locker Shop - A-103",
            coordinate: CLLocationCoordinate2D(latitude: 37.7697, longitude: -122.4269),
            address: "789 Howard St, San Francisco, CA 94103"
        )
    )
} 
