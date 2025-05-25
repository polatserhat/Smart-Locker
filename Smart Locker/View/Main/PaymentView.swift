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
    @State private var isCardFlipped = false
    
    let rental: LockerRental
    let location: LockerLocation
    
    // Check if this is a completing an existing rental
    private var isCompletingExistingRental: Bool {
        return rental.startTime != nil && rental.status == .active
    }
    
    let paymentMethods = [
        PaymentMethod(name: "Credit Card", icon: "creditcard.fill", isSelected: true),
        PaymentMethod(name: "Apple Pay", icon: "apple.logo", isSelected: false),
        PaymentMethod(name: "Account Balance", icon: "wallet.pass.fill", isSelected: false)
    ]
    
    private var totalPrice: Double {
        if isCompletingExistingRental {
            return rental.totalPrice ?? 0
        }
        
        if rental.rentalType == .reservation {
            return rental.size.basePrice * 2.0
        }
        
        return rental.totalPrice ?? (rental.plan?.price ?? rental.size.basePrice) * 1.1
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Simple Header
            Text("Payment")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Simple Order Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total Amount")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("€\(String(format: "%.2f", totalPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        HStack {
                            Text("\(rental.shopName) • \(rental.size.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(AppColors.surface)
                    .cornerRadius(16)
                    
                    // Simple Payment Methods
                    VStack(spacing: 12) {
                        ForEach(paymentMethods) { method in
                            Button(action: {
                                selectedPaymentMethod = method
                            }) {
                                HStack {
                                    Image(systemName: method.icon)
                                        .font(.title3)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(method.name)
                                        .font(.body)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if selectedPaymentMethod?.id == method.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                                .padding(16)
                                .background(selectedPaymentMethod?.id == method.id ? AppColors.primary.opacity(0.1) : AppColors.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPaymentMethod?.id == method.id ? AppColors.primary : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    
                    // Credit Card with Flip Animation
                    if selectedPaymentMethod?.name == "Credit Card" {
                        VStack(spacing: 16) {
                            // Credit Card
                            ZStack {
                                // Front of Card
                                if !isCardFlipped {
                                    CreditCardFront(
                                        cardNumber: paymentDetails.cardNumber,
                                        cardholderName: paymentDetails.cardholderName
                                    )
                                    .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                                }
                                
                                // Back of Card
                                if isCardFlipped {
                                    CreditCardBack(
                                        expiryDate: paymentDetails.expiryDate,
                                        cvv: paymentDetails.cvv
                                    )
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                }
                            }
                            .frame(height: 200)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                                    isCardFlipped.toggle()
                                }
                            }
                            
                            // Simple Input Fields
                            if !isCardFlipped {
                                VStack(spacing: 12) {
                                    InputField(title: "Card Number", text: $paymentDetails.cardNumber, keyboardType: .numberPad)
                                        .onChange(of: paymentDetails.cardNumber) { newValue in
                                            // Only allow numbers and limit to 16 characters
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count <= 16 {
                                                paymentDetails.cardNumber = filtered
                                            } else {
                                                paymentDetails.cardNumber = String(filtered.prefix(16))
                                            }
                                        }
                                    
                                    InputField(title: "Cardholder Name", text: $paymentDetails.cardholderName, keyboardType: .alphabet)
                                        .onChange(of: paymentDetails.cardholderName) { newValue in
                                            // Only allow letters and spaces, limit to 30 characters
                                            let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                                            if filtered.count <= 30 {
                                                paymentDetails.cardholderName = filtered
                                            } else {
                                                paymentDetails.cardholderName = String(filtered.prefix(30))
                                            }
                                        }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        InputField(title: "MM/YY", text: $paymentDetails.expiryDate, keyboardType: .numberPad)
                                            .onChange(of: paymentDetails.expiryDate) { newValue in
                                                // Only allow numbers and format as MM/YY
                                                let filtered = newValue.filter { $0.isNumber }
                                                var formatted = ""
                                                
                                                for (index, character) in filtered.enumerated() {
                                                    if index == 2 {
                                                        formatted += "/"
                                                    }
                                                    if index < 4 {
                                                        formatted += String(character)
                                                    }
                                                }
                                                
                                                paymentDetails.expiryDate = formatted
                                            }
                                        
                                        InputField(title: "CVV", text: $paymentDetails.cvv, isSecure: true, keyboardType: .numberPad)
                                            .onChange(of: paymentDetails.cvv) { newValue in
                                                // Only allow numbers and limit to 3 characters
                                                let filtered = newValue.filter { $0.isNumber }
                                                if filtered.count <= 3 {
                                                    paymentDetails.cvv = filtered
                                                } else {
                                                    paymentDetails.cvv = String(filtered.prefix(3))
                                                }
                                            }
                                    }
                                }
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                                    isCardFlipped.toggle()
                                }
                            }) {
                                Text(isCardFlipped ? "Edit Card Info" : "Enter Expiry & CVV")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Simple Buttons
            VStack(spacing: 12) {
                Button(action: {
                    processPayment()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Pay €\(String(format: "%.2f", totalPrice))")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentConfirmationView(rental: rental, location: location)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "An error occurred")
        }
        .onAppear {
            selectedPaymentMethod = paymentMethods.first
        }
    }
    
    private func processPayment() {
        guard let userId = authViewModel.currentUser?.id else {
            error = "User not logged in"
            showError = true
            return
        }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            
            if rental.rentalType == .reservation {
                createReservation()
            } else {
                showConfirmation = true
            }
        }
    }
    
    private func createReservation() {
        NotificationCenter.default.post(name: Notification.Name("ReservationCreated"), object: rental)
        NotificationCenter.default.post(name: Notification.Name("DismissToRoot"), object: nil)
    }
}

// Credit Card Front View
struct CreditCardFront: View {
    let cardNumber: String
    let cardholderName: String
    
    var body: some View {
        ZStack {
            // Card Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("SMART LOCKER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : formatCardNumber(cardNumber))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .tracking(2)
                
                HStack {
                    Text(cardholderName.isEmpty ? "CARDHOLDER NAME" : cardholderName.uppercased())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .padding(24)
        }
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        // Pad with dots if less than 16 digits
        let remainingDigits = 16 - cleaned.count
        if remainingDigits > 0 {
            let groups = (remainingDigits + 3) / 4 // Calculate how many groups of 4 we need
            for groupIndex in 0..<groups {
                if !formatted.isEmpty {
                    formatted += " "
                }
                let digitsInThisGroup = min(4, remainingDigits - (groupIndex * 4))
                formatted += String(repeating: "•", count: digitsInThisGroup)
            }
        }
        
        return formatted
    }
}

// Credit Card Back View
struct CreditCardBack: View {
    let expiryDate: String
    let cvv: String
    
    var body: some View {
        ZStack {
            // Card Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 16) {
                // Magnetic Strip
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 40)
                    .padding(.horizontal, -24)
                    .padding(.top, 20)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VALID THRU")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("CVV")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Text(cvv.isEmpty ? "•••" : cvv)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .scaleEffect(x: -1, y: 1) // Flip horizontally for back view
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

