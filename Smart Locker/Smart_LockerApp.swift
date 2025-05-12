//
//  Smart_LockerApp.swift
//  Smart Locker
//
//  Created by Serhat  on 07.03.25.
//

import SwiftUI
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Initialize lockers after Firebase is configured
        DispatchQueue.main.async {
            print("🔥 Firebase configured, initializing lockers...")
            LockerInitializer.clearExistingLockers {
                LockerInitializer.initializeLockers()
            }
        }
        return true
    }
}

@main
struct SmartLockerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel() // ✅ Ensuring Singleton Instance
    @StateObject private var reservationViewModel = ReservationViewModel() // ✅ Singleton for Reservations
    @AppStorage("isDarkMode") private var isDarkMode = false

    init() {
        print("📱 App starting, initializing locker system...")
        
        // Wait for Firebase to be fully configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("🔥 Firebase should be configured now, initializing lockers...")
            
            // Force reinitialize lockers
            LockerInitializer.initializeLockers()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environmentObject(authViewModel) // ✅ Providing AuthViewModel to All Views
                .environmentObject(reservationViewModel) // ✅ Providing ReservationViewModel to All Views
                .onAppear {
                    // Ensure shared instance is set
                    AuthViewModel.shared = authViewModel
                    
                    // If user is already logged in, fetch their rentals
                    if let userId = Auth.auth().currentUser?.uid {
                        reservationViewModel.fetchRentals(for: userId)
                    }
                }
        }
    }
}

// ✅ Create a Wrapper View to Handle Navigation Logic
struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                HomeView()
                    .onReceive(authViewModel.$navigateToHome) { navigate in
                        if navigate {
                            // Reset the flag after navigation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                authViewModel.navigateToHome = false
                            }
                        }
                    }
            } else {
                OnboardingView()
            }
        }
    }
}

// ✅ Preview Provider for MainView
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel()
        let mockReservationViewModel = ReservationViewModel()
        
        return MainView()
            .environmentObject(mockAuthViewModel)
            .environmentObject(mockReservationViewModel)
    }
}
