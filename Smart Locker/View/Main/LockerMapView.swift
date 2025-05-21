import SwiftUI
import MapKit
import FirebaseFirestore

struct LockerLocation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    var availableLockers: [String: Int] = [:] // Count by size
    var totalLockers: Int = 0
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D, address: String) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
    
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
    @StateObject private var viewModel = LockerMapViewModel()
    
    @State private var selectedLocation: LockerLocation?
    @State private var showingLockerDetails = false
    @State private var showingDirectionsSheet = false
    @State private var navigateToLockerSelection = false
    
    // For reservation flow
    var reservationDates: Set<Date>?
    var isReservationFlow: Bool {
        reservationDates != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.locations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        Button {
                            selectedLocation = location
                        } label: {
                            VStack(spacing: 0) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(location == selectedLocation ? AppColors.secondary : AppColors.primary)
                                    .padding(8)
                                    .background(AppColors.surface)
                                    .clipShape(Circle())
                                    .shadow(color: AppColors.shadow, radius: 4, y: 2)
                                
                                if location == selectedLocation {
                                    Rectangle()
                                        .fill(AppColors.secondary)
                                        .frame(width: 4, height: 8)
                                }
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                // Search bar
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(10)
                                .background(AppColors.surface)
                                .clipShape(Circle())
                                .shadow(color: AppColors.shadow, radius: 4, y: 2)
                        }
                        
                        Spacer()
                        
                        Text(isReservationFlow ? "Select Location" : "Find a Locker")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button {
                            viewModel.requestLocationPermission()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(10)
                                .background(AppColors.surface)
                                .clipShape(Circle())
                                .shadow(color: AppColors.shadow, radius: 4, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("Search locations", text: $viewModel.searchText)
                            .foregroundColor(AppColors.textPrimary)
                            .accentColor(AppColors.secondary)
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(AppColors.surface)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .shadow(color: AppColors.shadow, radius: 4, y: 2)
                }
                .background(AppColors.background.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .top)
                
                // Location Detail Card
                if let location = selectedLocation {
                    LocationDetailCard(
                        location: location,
                        onDismiss: { selectedLocation = nil },
                        onSelect: {
                            showingLockerDetails = true
                        }
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: selectedLocation)
                }
            }
            .navigationDestination(isPresented: $showingLockerDetails) {
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
            .onAppear {
                viewModel.fetchLockerLocations()
                
                if let userLocation = viewModel.userLocation {
                    viewModel.region.center = userLocation
                }
                
                print("LockerMapView appeared with rental type: \(isReservationFlow ? "Reservation" : "Instant"), reservation date: \(String(describing: reservationDates))")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshLockerMap"))) { _ in
                print("🔄 Refreshing locker map...")
                viewModel.fetchLockerLocations()
            }
        }
    }
}

struct LocationDetailCard: View {
    let location: LockerLocation
    let onDismiss: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with name and dismiss button
            HStack {
                Text(location.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(8)
                        .background(AppColors.surface)
                        .clipShape(Circle())
                }
            }
            
            // Address
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(AppColors.textSecondary)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
                .background(AppColors.border)
            
            // Availability info
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Now")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sizes")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("S, M, L")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starting at")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("$2.99/hr")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            // Select button
            Button(action: onSelect) {
                HStack {
                    Text("Select This Location")
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8, y: 4)
        .padding(.horizontal, 24)
    }
}

class LockerMapViewModel: ObservableObject {
    @Published var locations: [LockerLocation] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var searchText = ""
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    
    func fetchLockerLocations() {
        print("🔍 Fetching locker locations...")
        
        // Get all lockers and group by location
        db.collection("lockers")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    print("❌ Error fetching lockers: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                print("📦 Found \(documents.count) lockers")
                
                // Group lockers by location
                var locationDict: [String: (name: String, address: String, coordinates: CLLocationCoordinate2D, counts: [String: Int], availableCounts: [String: Int])] = [:]
                
                for document in documents {
                    let data = document.data()
                    guard let locationId = data["locationId"] as? String,
                          let locationName = data["locationName"] as? String,
                          let locationAddress = data["locationAddress"] as? String,
                          let coordinates = data["coordinates"] as? [String: Any],
                          let latitude = coordinates["latitude"] as? Double,
                          let longitude = coordinates["longitude"] as? Double,
                          let size = data["size"] as? String,
                          let available = data["available"] as? Bool else {
                        print("⚠️ Skipping invalid locker document: \(document.documentID)")
                        continue
                    }
                    
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    
                    if var locationInfo = locationDict[locationId] {
                        // Update counts for existing location
                        locationInfo.counts[size, default: 0] += 1
                        if available {
                            locationInfo.availableCounts[size, default: 0] += 1
                        }
                        locationDict[locationId] = locationInfo
                    } else {
                        // Create new location entry
                        locationDict[locationId] = (
                            name: locationName,
                            address: locationAddress,
                            coordinates: coordinate,
                            counts: [size: 1],
                            availableCounts: available ? [size: 1] : [:]
                        )
                    }
                }
                
                // Convert dictionary to location array
                self.locations = locationDict.map { (locationId, info) in
                    var location = LockerLocation(
                        id: UUID(uuidString: locationId) ?? UUID(),
                        name: info.name,
                        coordinate: info.coordinates,
                        address: info.address
                    )
                    
                    // Set available lockers to the actual available count
                    location.availableLockers = info.availableCounts
                    location.totalLockers = info.counts.values.reduce(0, +)
                    return location
                }
                
                // Sort locations by name
                self.locations.sort { $0.name < $1.name }
                
                // Center map on first location
                if let firstLocation = self.locations.first {
                    self.region = MKCoordinateRegion(
                        center: firstLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
                
                print("📍 Processed locations:")
                for location in self.locations {
                    print("  \(location.name):")
                    print("    Total lockers: \(location.totalLockers)")
                    print("    Available: \(location.availableLockers)")
                }
            }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let location = locationManager.location?.coordinate {
            userLocation = location
        }
    }
}

// Availability card component
struct AvailabilityCard: View {
    let size: String
    let locationId: String
    let dimensions: String
    let availableCount: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Text(size)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("\(availableCount)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            Text(dimensions)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(height: 26)
            
            // Show Available/Full tag based on availability 
            Text(availableCount > 0 ? "Available" : "Full")
                .font(.system(size: 10))
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(availableCount > 0 ? AppColors.secondary : Color.red)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: AppColors.shadow, radius: 5, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        LockerMapView()
            .preferredColorScheme(.dark)
    }
}

// Sample Data Extension
extension LockerLocation {
    static let sampleLocations = [
        LockerLocation(
            name: "Smart Locker Shop - A-001",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Market St, San Francisco, CA 94105"
        ).with(availableLockers: ["Small": 3, "Medium": 2, "Large": 1]),
        LockerLocation(
            name: "Smart Locker Shop - B-001",
            coordinate: CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.4089),
            address: "456 Mission St, San Francisco, CA 94105"
        ).with(availableLockers: ["Small": 2, "Medium": 3, "Large": 2]),
        LockerLocation(
            name: "Smart Locker Shop - C-001",
            coordinate: CLLocationCoordinate2D(latitude: 37.7697, longitude: -122.4269),
            address: "789 Howard St, San Francisco, CA 94103"
        ).with(availableLockers: ["Small": 4, "Medium": 1, "Large": 0]),
        LockerLocation(
            name: "Smart Locker Shop - D-001",
            coordinate: CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4074),
            address: "101 California St, San Francisco, CA 94111"
        ).with(availableLockers: ["Small": 1, "Medium": 4, "Large": 3]),
        LockerLocation(
            name: "Smart Locker Shop - E-001",
            coordinate: CLLocationCoordinate2D(latitude: 37.7785, longitude: -122.4314),
            address: "333 Post St, San Francisco, CA 94108"
        ).with(availableLockers: ["Small": 5, "Medium": 2, "Large": 1])
    ]
    
    // Helper function to set available lockers
    func with(availableLockers: [String: Int]) -> LockerLocation {
        var copy = self
        copy.availableLockers = availableLockers
        copy.totalLockers = availableLockers.values.reduce(0, +)
        return copy
    }
}
