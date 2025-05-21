import SwiftUI
import MapKit

struct LockerConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var navigateToPayment = false
    @State private var isProcessing = false
    @State private var error: String?
    @State private var showError = false
    
    let rental: LockerRental
    let location: LockerLocation
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Locker Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Confirm your selected locker")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 20)
            
            // Location Map
            VStack(alignment: .leading, spacing: 16) {
                Text("Location")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                ZStack(alignment: .bottom) {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [AnnotationItem(coordinate: location.coordinate)]) { item in
                        MapMarker(coordinate: item.coordinate, tint: AppColors.secondary)
                    }
                    .frame(height: 180)
                    .cornerRadius(12)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(12)
                    .background(AppColors.surface)
                    .cornerRadius(8)
                    .padding(12)
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 10)
            
            // Locker Details
            VStack(alignment: .leading, spacing: 16) {
                Text("Selected Locker")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 18) {
                    // Locker Size Visualization
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 80, height: 80)
                            .foregroundColor(AppColors.secondary.opacity(0.2))
                            .overlay(
                                Image(systemName: sizeIcon(for: rental.size))
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColors.secondary)
                            )
                        
                        Text(rental.size.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        LockerDetailRow(title: "Dimensions", value: rental.size.dimensions)
                        LockerDetailRow(title: "Max Weight", value: rental.size.maxWeight)
                        LockerDetailRow(title: "Hourly Rate", value: "$\(String(format: "%.2f", rental.size.basePrice))/hour")
                        LockerDetailRow(title: "Availability", value: "Available Now", highlighted: true)
                    }
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: AppColors.background.opacity(0.3), radius: 10)
            
            Spacer()
            
            // CTA Buttons
            VStack(spacing: 16) {
                Button(action: {
                    proceedToPlans()
                }) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            .frame(height: 24)
                    } else {
                        Text("Select This Locker")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.primary)
                .cornerRadius(16)
                .shadow(color: AppColors.background.opacity(0.4), radius: 4, y: 2)
                .disabled(isProcessing)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Go Back")
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .background(AppColors.background)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "An error occurred")
        }
        .fullScreenCover(isPresented: $navigateToPayment) {
            PlanSelectionView(rental: rental, location: location)
        }
    }
    
    private func sizeIcon(for size: LockerSize) -> String {
        switch size {
        case .small: return "briefcase"
        case .medium: return "bag"
        case .large: return "cube.box"
        }
    }
    
    private func proceedToPlans() {
        guard authViewModel.currentUser != nil else {
            error = "You need to be logged in to rent a locker"
            showError = true
            return
        }
        
        isProcessing = true
        
        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isProcessing = false
            navigateToPayment = true
        }
    }
}

struct LockerDetailRow: View {
    let title: String
    let value: String
    var highlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(highlighted ? .semibold : .regular)
                .foregroundColor(highlighted ? AppColors.secondary : AppColors.textPrimary)
        }
    }
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    LockerConfirmationView(
        rental: LockerRental(
            id: UUID().uuidString,
            shopName: "Airport Terminal 1",
            size: LockerSize.medium,
            rentalType: RentalType.instant,
            reservationDate: nil,
            startTime: nil,
            endTime: nil,
            status: .pending,
            totalPrice: nil,
            plan: nil
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