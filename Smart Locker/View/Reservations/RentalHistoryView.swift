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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rental.locationName)
                    .font(.headline)
                
                Spacer()
                
                Text(rental.status)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Size: \(rental.size)")
                Spacer()
                Text("Locker: \(rental.lockerId)")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            HStack {
                Text(rental.startDate, style: .date)
                Text("-")
                Text(rental.endDate, style: .date)
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
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
        
        // Create a simple rental for preview
        let sampleRental = Rental(
            id: "sample-1",
            userId: "user-1",
            lockerId: "locker_001",
            locationName: "Smart Locker Shop - A-101",
            size: "Small",
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date(),
            status: "completed"
        )
        
        viewModel.pastRentals = [sampleRental]
        
        return RentalHistoryView()
            .environmentObject(viewModel)
    }
} 