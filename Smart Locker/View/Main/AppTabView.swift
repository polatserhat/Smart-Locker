import SwiftUI
import UIKit

/// AppTabView serves as the main navigation container using a tab bar
/// This allows users to navigate between the main sections of the app
struct AppTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    
    @State private var selectedTab = 0
    @State private var animationScale: CGFloat = 1.0
    
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
    
    private func animateTabChange() {
        withAnimation(.easeInOut(duration: 0.1)) {
            animationScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animationScale = 1.0
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .scaleEffect(selectedTab == 0 ? animationScale : 1.0)
                .opacity(selectedTab == 0 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Map Tab
            LockerMapView()
                .scaleEffect(selectedTab == 1 ? animationScale : 1.0)
                .opacity(selectedTab == 1 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Find")
                }
                .tag(1)
            
            // History Tab
            VStack {
                if reservationViewModel.currentRentals.isEmpty {
                    RentalHistoryView()
                } else {
                    ActiveRentalsView()
                }
            }
            .scaleEffect(selectedTab == 2 ? animationScale : 1.0)
            .opacity(selectedTab == 2 ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            .tabItem {
                Image(systemName: "calendar.badge.clock")
                Text("History")
            }
            .tag(2)
            
            // Profile Tab
            ProfilePageView()
                .scaleEffect(selectedTab == 3 ? animationScale : 1.0)
                .opacity(selectedTab == 3 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(AppColors.secondary) // Use the accent color from our theme
        .onChange(of: selectedTab) { _ in
            animateTabChange()
        }
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