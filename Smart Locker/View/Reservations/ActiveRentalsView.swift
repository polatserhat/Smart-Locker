import SwiftUI
import FirebaseFirestore

struct ActiveRentalsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(AppColors.primary)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Text("Active Rentals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Empty spacer for visual balance
                Image(systemName: "arrow.left")
                    .foregroundColor(.clear)
                    .imageScale(.large)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            if reservationViewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if reservationViewModel.currentRentals.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 70))
                        .foregroundColor(AppColors.secondary)
                    
                    Text("No Active Rentals")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("You don't have any active locker rentals. Rent a locker to see your active rentals here.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(reservationViewModel.currentRentals) { rental in
                            ActiveRentalCard(rental: rental)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Active Rental Card View
struct ActiveRentalCard: View {
    let rental: Rental
    
    // Format dates for display
    private var formattedStartDate: String {
        rental.startDate.formatted(date: .abbreviated, time: .shortened)
    }
    
    private var formattedEndDate: String {
        rental.endDate.formatted(date: .abbreviated, time: .shortened)
    }
    
    // Time remaining until expiration
    private var timeRemaining: String {
        let now = Date()
        let end = rental.endDate
        
        if now > end {
            return "Expired"
        }
        
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: end)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") left"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") left"
        }
        
        return "Ending soon"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with location name
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.secondary)
                
                Text(rental.locationName)
                    .font(.headline)
                
                Spacer()
                
                // Time remaining tag
                Text(timeRemaining)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Basic details
            VStack(spacing: 12) {
                // Locker ID
                ActiveRentalDetailRow(icon: "location.fill", title: "Locker ID", value: rental.lockerId)
                
                // Size
                ActiveRentalDetailRow(icon: "shippingbox.fill", title: "Size", value: rental.size)
                
                // Date range
                ActiveRentalDetailRow(icon: "calendar", title: "Period", value: "\(formattedStartDate) - \(formattedEndDate)")
            }
            
            // Actions
            HStack(spacing: 16) {
                Spacer()
                
                NavigationLink(destination: Text("QR Code Access Screen")) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Access")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.primary)
                    .cornerRadius(10)
                }
                
                NavigationLink(destination: Text("Extend Rental Screen")) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Extend")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.secondary)
                    .cornerRadius(10)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Detail Row
struct ActiveRentalDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .font(.subheadline)
    }
}

// MARK: - Preview
struct ActiveRentalsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ReservationViewModel()
        
        // Add sample data for preview
        let sampleRental = Rental(
            id: "sample-1",
            userId: "user-1",
            lockerId: "locker_001",
            locationName: "Smart Locker Shop - A-101",
            size: "Small",
            startDate: Date(),
            endDate: Date().addingTimeInterval(24 * 3600), // 1 day later
            status: "active"
        )
        
        viewModel.currentRentals = [sampleRental]
        
        return ActiveRentalsView()
            .environmentObject(viewModel)
    }
} 