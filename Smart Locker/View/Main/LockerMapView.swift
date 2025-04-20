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
    @State private var showingDirectionsSheet = false
    @State private var navigateToLockerSelection = false
    
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
            
            // Location Details Sheet
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
                    
                    // Locker Availability Section
                    VStack(spacing: 16) {
                        Text("Available Lockers")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            // Small Lockers
                            VStack {
                                Text("Small")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("27")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryBlack)
                                
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Medium Lockers
                            VStack {
                                Text("Medium")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("24")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryBlack)
                                
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Large Lockers
                            VStack {
                                Text("Large")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("29")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryBlack)
                                
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Shop Hours and Extra Info
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(AppColors.primaryYellow)
                            Text("Open 24/7")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(AppColors.primaryYellow)
                            Text("Security Cameras")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Select Locker Button
                    Button(action: {
                        if let location = selectedLocation {
                            showingLockerDetails = false
                            navigateToLockerSelection = true
                        }
                    }) {
                        Text("Continue to Select Locker")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primaryBlack)
                            .cornerRadius(16)
                    }
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
        .fullScreenCover(isPresented: $navigateToLockerSelection) {
            if let location = selectedLocation {
                LockerSelectionView(
                    location: location,
                    rentalType: isReservationFlow ? .reservation : .instant,
                    reservationDates: reservationDates
                )
                .environmentObject(AuthViewModel.shared ?? AuthViewModel())
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
