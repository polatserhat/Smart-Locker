import SwiftUI
import MapKit

struct LockerLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct LockerSizeOption: Identifiable {
    let id = UUID()
    let name: String
    let dimensions: String
    let color: Color
}

struct LockerMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedLocation: LockerLocation?
    @State private var showingLockerDetails = false
    
    let sizeOptions = [
        LockerSizeOption(name: "Small", dimensions: "40x30x45 cm", color: .green),
        LockerSizeOption(name: "Medium", dimensions: "70x50x60 cm", color: .blue),
        LockerSizeOption(name: "Large", dimensions: "100x80x70 cm", color: .red)
    ]
    
    // Sample locations - in a real app, these would come from a backend
    let locations = [
        LockerLocation(name: "Smart Locker Shop - A-101", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
        LockerLocation(name: "Smart Locker Shop - A-102", coordinate: CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.4089)),
        LockerLocation(name: "Smart Locker Shop - A-103", coordinate: CLLocationCoordinate2D(latitude: 37.7697, longitude: -122.4269))
    ]
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        selectedLocation = location
                        showingLockerDetails = true
                    }) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primaryBlack)
                            .background(Circle().fill(.white))
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
                            .foregroundColor(.primaryBlack)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                    
                    Text("Locker Shops Map")
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
                    // Shop Name
                    Text(selectedLocation?.name ?? "")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // Size Options
                    VStack(spacing: 16) {
                        Text("Select Locker Size")
                            .font(.headline)
                        
                        ForEach(sizeOptions) { option in
                            Button(action: {
                                // Handle size selection
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(option.name)
                                            .font(.headline)
                                        Text(option.dimensions)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 12, height: 12)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .foregroundColor(.black)
                        }
                    }
                    
                    // Rent Button
                    Button(action: {
                        // Handle rent action
                    }) {
                        Text("Rent Your Locker")
                            .fontWeight(.bold)
                            .foregroundColor(.primaryBlack)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryYellow)
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
    }
}

struct LockerMapView_Previews: PreviewProvider {
    static var previews: some View {
        LockerMapView()
    }
} 