import SwiftUI
import UIKit

/// AppTabView serves as the main navigation container using a tab bar
/// This allows users to navigate between the main sections of the app
struct AppTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    
    @State private var selectedTab = 0
    
    init() {
        // Configure tab bar appearance for dark mode
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(AppColors.surface)
        
        // Configure the normal state appearance
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppColors.textSecondary)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary)
        
        // Configure the selected state appearance
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppColors.secondary)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.secondary)
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Map Tab
            LockerMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Find")
                }
                .tag(1)
            
            // Bookings Tab
            VStack {
                if reservationViewModel.currentRentals.isEmpty {
                    RentalHistoryView()
                } else {
                    ActiveRentalsView()
                }
            }
            .tabItem {
                Image(systemName: "calendar.badge.clock")
                Text("Bookings")
            }
            .tag(2)
            
            // Profile Tab
            ProfilePageView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(AppColors.secondary) // Use the accent color from our theme
        .onAppear {
            // If user is already logged in, fetch their rentals
            if let userId = authViewModel.currentUser?.id {
                reservationViewModel.fetchRentals(for: userId)
            }
        }
        .background(AppColors.background)
        .preferredColorScheme(.dark) // Ensure dark mode even if system theme changes
    }
}

struct AppTabView_Previews: PreviewProvider {
    static var previews: some View {
        AppTabView()
            .environmentObject(AuthViewModel())
            .environmentObject(ReservationViewModel())
            .preferredColorScheme(.dark)
    }
} 