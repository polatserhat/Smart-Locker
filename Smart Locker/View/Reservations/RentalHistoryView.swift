import SwiftUI
import FirebaseFirestore

struct RentalHistoryView: View {
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
                        .foregroundColor(AppColors.primaryBlack)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Text("Rental History")
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
            } else if reservationViewModel.pastRentals.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 70))
                        .foregroundColor(AppColors.primaryYellow)
                    
                    Text("No Rental History")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Your past rentals will appear here once you've completed them.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(reservationViewModel.pastRentals) { rental in
                            RentalCard(rental: rental)
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

// MARK: - Rental Card View
struct RentalCard: View {
    let rental: Rental
    
    // Format dates for display
    private var formattedStartDate: String {
        rental.startDate.dateValue().formatted(date: .abbreviated, time: .shortened)
    }
    
    private var formattedEndDate: String {
        rental.endDate.dateValue().formatted(date: .abbreviated, time: .shortened)
    }
    
    // Duration in hours, rounded to 1 decimal place
    private var duration: String {
        let seconds = rental.endDate.dateValue().timeIntervalSince(rental.startDate.dateValue())
        let hours = seconds / 3600
        return String(format: "%.1f hrs", hours)
    }
    
    // Format price with currency
    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        
        if let priceString = formatter.string(from: NSNumber(value: rental.totalPrice)) {
            return priceString
        }
        
        return "$\(rental.totalPrice)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with location name and status
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primaryYellow)
                
                Text(rental.locationName)
                    .font(.headline)
                
                Spacer()
                
                Text(rental.status.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBackgroundColor)
                    .foregroundColor(statusForegroundColor)
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Details
            VStack(spacing: 12) {
                // Address
                RentalDetailRow(icon: "location.fill", title: "Address", value: rental.locationAddress)
                
                // Size
                RentalDetailRow(icon: "shippingbox.fill", title: "Size", value: "\(rental.size) (\(rental.dimensions))")
                
                // Date range
                RentalDetailRow(icon: "calendar", title: "Duration", value: "\(formattedStartDate) - \(formattedEndDate) (\(duration))")
                
                // Price
                RentalDetailRow(icon: "creditcard.fill", title: "Total Paid", value: formattedPrice)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
    
    // Handle status colors
    private var statusBackgroundColor: Color {
        switch rental.status.lowercased() {
        case "completed":
            return Color.green.opacity(0.2)
        case "cancelled":
            return Color.red.opacity(0.2)
        default:
            return Color.orange.opacity(0.2)
        }
    }
    
    private var statusForegroundColor: Color {
        switch rental.status.lowercased() {
        case "completed":
            return Color.green
        case "cancelled":
            return Color.red
        default:
            return Color.orange
        }
    }
}

// MARK: - Detail Row
struct RentalDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryBlack)
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

// Preview provider
struct RentalHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ReservationViewModel()
        
        // Add sample data for preview
        let sampleRental = Rental(
            id: "sample-1",
            userId: "user-1",
            locationId: "loc-1",
            locationName: "Smart Locker Shop - A-101",
            locationAddress: "123 Market St, San Francisco, CA 94105",
            coordinates: GeoPoint(latitude: 37.7749, longitude: -122.4194),
            size: "Small",
            dimensions: "30 x 30 x 45 cm",
            startDate: Timestamp(date: Date().addingTimeInterval(-86400)),
            endDate: Timestamp(date: Date()),
            totalPrice: 24.99,
            status: "completed",
            createdAt: Timestamp(date: Date().addingTimeInterval(-86400)),
            updatedAt: nil
        )
        
        viewModel.pastRentals = [sampleRental]
        
        return RentalHistoryView()
            .environmentObject(viewModel)
    }
} 