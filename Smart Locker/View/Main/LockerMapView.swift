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
                    VStack(spacing: 0) {
                        Button(action: {
                            selectedLocation = location
                            showingLockerDetails = true
                        }) {
                            ZStack {
                                // Shadow circle underneath
                                Circle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .offset(y: 1)
                                
                                // Main circular pin
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.primaryYellow, lineWidth: 2)
                                    )
                                
                                // Icon inside pin
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.primaryBlack)
                            }
                        }
                        
                        // Label shown when tapped
                        if selectedLocation?.id == location.id {
                            Text(location.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                                .offset(y: 5)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: selectedLocation?.id == location.id)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            // Search box at the top
            VStack {
                VStack(spacing: 0) {
                    // Header with back button and title
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primaryBlack)
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        Text(isReservationFlow ? "Select Location" : "Find a Locker")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryBlack)
                        
                        Spacer()
                        
                        Button(action: {
                            // This is a placeholder UI element for visual balance
                        }) {
                            Color.clear
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Search bar (non-functional, just for design)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        Text("Search for a location")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom status bar showing number of locations
                HStack {
                    Text("\(locations.count) locations near you")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Center map on user location (placeholder)
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(AppColors.primaryYellow)
                            .clipShape(Circle())
                    }
                }
                .padding(12)
                .background(AppColors.primaryBlack)
                .cornerRadius(12)
                .padding(16)
            }
            
            // Location Details Sheet
            if showingLockerDetails {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingLockerDetails = false
                    }
                
                VStack(spacing: 20) {
                    // Header with handle line
                    VStack(spacing: 16) {
                        // Draggable handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 5)
                        
                        // Shop name and address
                        VStack(spacing: 4) {
                            HStack {
                                Text(selectedLocation?.name ?? "")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingDirectionsSheet = true
                                }) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppColors.primaryYellow)
                                }
                            }
                            
                            HStack {
                                Text(selectedLocation?.address ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Locker Availability Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Lockers")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryBlack)
                        
                        HStack(spacing: 12) {
                            // Small Lockers
                            AvailabilityCard(
                                size: "Small",
                                count: 27,
                                dimensions: "30 x 30 x 45 cm"
                            )
                            
                            // Medium Lockers
                            AvailabilityCard(
                                size: "Medium",
                                count: 24,
                                dimensions: "45 x 45 x 60 cm"
                            )
                            
                            // Large Lockers
                            AvailabilityCard(
                                size: "Large",
                                count: 29,
                                dimensions: "60 x 60 x 90 cm"
                            )
                        }
                    }
                    
                    // Amenities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Amenities")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryBlack)
                        
                        HStack(spacing: 24) {
                            // Opening hours
                            VStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(AppColors.primaryYellow)
                                    .font(.system(size: 20))
                                
                                Text("24/7")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            // Security
                            VStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(AppColors.primaryYellow)
                                    .font(.system(size: 20))
                                
                                Text("Secure")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            // Covered
                            VStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(AppColors.primaryYellow)
                                    .font(.system(size: 20))
                                
                                Text("Indoor")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            // Accessibility
                            VStack(spacing: 4) {
                                Image(systemName: "figure.roll")
                                    .foregroundColor(AppColors.primaryYellow)
                                    .font(.system(size: 20))
                                
                                Text("Accessible")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    // Select Locker Button
                    Button(action: {
                        if let location = selectedLocation {
                            showingLockerDetails = false
                            navigateToLockerSelection = true
                        }
                    }) {
                        Text("Select This Location")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.primaryBlack)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showingLockerDetails)
                .frame(maxHeight: 500)
                .padding(.horizontal)
                .padding(.bottom, -20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

// Availability card component
struct AvailabilityCard: View {
    let size: String
    let count: Int
    let dimensions: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(size)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.primaryBlack)
            
            Text(dimensions)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(height: 26)
            
            Text("Available")
                .font(.system(size: 10))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .cornerRadius(10)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
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
