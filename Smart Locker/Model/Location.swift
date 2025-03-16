import Foundation
import CoreLocation

enum LocationCategory: String, CaseIterable {
    case airports = "Airports"
    case stations = "Stations"
    case cityCenters = "City Centers"
    
    var icon: String {
        switch self {
        case .airports: return "airplane"
        case .stations: return "tram.fill"
        case .cityCenters: return "building.2.fill"
        }
    }
}

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let category: LocationCategory
    let coordinate: CLLocationCoordinate2D
    let address: String
    
    // For MVP, we'll create some sample data
    static let sampleLocations = [
        Location(
            name: "JFK Airport",
            category: .airports,
            coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781),
            address: "Queens, NY 11430"
        ),
        Location(
            name: "Grand Central Terminal",
            category: .stations,
            coordinate: CLLocationCoordinate2D(latitude: 40.7527, longitude: -73.9772),
            address: "89 E 42nd Street, New York, NY 10017"
        ),
        Location(
            name: "Times Square",
            category: .cityCenters,
            coordinate: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
            address: "Manhattan, NY 10036"
        )
    ]
} 