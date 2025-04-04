import SwiftUI
import MapKit

struct LockerLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    
    // Function to open directions in Apple Maps
    func openInMaps() {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = name
        
        // Try to open in Apple Maps with driving directions
        MKMapItem.openMaps(
            with: [destination],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
    
    // Function to open in Google Maps if available
    func openInGoogleMaps() {
        let urlString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to Google Maps web URL
            let webUrlString = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)"
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}

struct LockerMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedLocation: LockerLocation?
    @State private var showingLockerDetails = false
    @State private var selectedSize: LockerSize?
    @State private var showConfirmation = false
    @State private var showingDirectionsSheet = false
    
    // For reservation flow
    var reservationDates: Set<Date>?
    var isReservationFlow: Bool {
        reservationDates != nil
    }
    
    // Use sample locations
    let locations = LockerLocation.sampleLocations
    
    var body: some View {
        ZStack {
            // Map with annotations
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack(spacing: 4) {
                        Button(action: {
                            selectedLocation = location
                            showingLockerDetails = true
                        }) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(AppColors.primaryBlack)
                                .background(Circle().fill(.white))
                                .shadow(radius: 5)
                        }
                        
                        // Location name label
                        Text(location.name)
                            .font(.caption)
                            .padding(6)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Header
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.primaryBlack)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                    
                    Text(isReservationFlow ? "Select Location" : "Locker Shops Map")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                Spacer()
            }
            
            // Locker Details Sheet
            if showingLockerDetails {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingLockerDetails = false
                    }
                
                VStack(spacing: 24) {
                    // Shop Name and Address
                    VStack(spacing: 8) {
                        Text(selectedLocation?.name ?? "")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(selectedLocation?.address ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Directions Button
                    Button(action: {
                        showingDirectionsSheet = true
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Get Directions")
                        }
                        .foregroundColor(AppColors.primaryYellow)
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    // Size Options
                    VStack(spacing: 16) {
                        Text("Select Locker Size")
                            .font(.headline)
                        
                        ForEach(LockerSize.allCases, id: \.self) { size in
                            Button(action: {
                                selectedSize = size
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(size.rawValue)
                                            .font(.headline)
                                        Text(size.dimensions)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$\(String(format: "%.2f", size.basePrice))")
                                        .font(.headline)
                                        .foregroundColor(AppColors.primaryBlack)
                                    
                                    if selectedSize == size {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primaryYellow)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .foregroundColor(AppColors.primaryBlack)
                        }
                    }
                    
                    // Rent Button
                    Button(action: {
                        if let location = selectedLocation, let size = selectedSize {
                            showingLockerDetails = false
                            showConfirmation = true
                        }
                    }) {
                        Text(isReservationFlow ? "Confirm Selection" : "Rent Your Locker")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedSize == nil ? Color.gray : AppColors.primaryBlack)
                            .cornerRadius(16)
                            .opacity(selectedSize == nil ? 0.5 : 1)
                    }
                    .disabled(selectedSize == nil)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding()
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showingLockerDetails)
            }
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            if let location = selectedLocation, let size = selectedSize {
                LockerConfirmationView(
                    rental: LockerRental(
                        id: UUID().uuidString,
                        shopName: location.name,
                        size: size,
                        rentalType: isReservationFlow ? .reservation : .instant,
                        reservationDate: reservationDates?.first
                    ),
                    location: location
                )
            }
        }
        .confirmationDialog(
            "Get Directions",
            isPresented: $showingDirectionsSheet,
            titleVisibility: .visible
        ) {
            Button("Open in Apple Maps") {
                selectedLocation?.openInMaps()
            }
            
            Button("Open in Google Maps") {
                selectedLocation?.openInGoogleMaps()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose your preferred navigation app")
        }
    }
}

#Preview {
    NavigationView {
        LockerMapView()
    }
}

// Sample Data Extension
extension LockerLocation {
    static let sampleLocations = [
        LockerLocation(
            name: "Smart Locker Shop - A-101",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Market St, San Francisco, CA 94105"
        ),
        LockerLocation(
            name: "Smart Locker Shop - A-102",
            coordinate: CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.4089),
            address: "456 Mission St, San Francisco, CA 94105"
        ),
        LockerLocation(
            name: "Smart Locker Shop - A-103",
            coordinate: CLLocationCoordinate2D(latitude: 37.7697, longitude: -122.4269),
            address: "789 Howard St, San Francisco, CA 94103"
        ),
        LockerLocation(
            name: "Smart Locker Shop - B-101",
            coordinate: CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4074),
            address: "101 California St, San Francisco, CA 94111"
        ),
        LockerLocation(
            name: "Smart Locker Shop - B-102",
            coordinate: CLLocationCoordinate2D(latitude: 37.7785, longitude: -122.4314),
            address: "333 Post St, San Francisco, CA 94108"
        )
    ]
}
