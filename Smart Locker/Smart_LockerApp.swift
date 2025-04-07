//
//  Smart_LockerApp.swift
//  Smart Locker
//
//  Created by Serhat  on 07.03.25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SmartLockerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel() // ✅ Ensuring Singleton Instance

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authViewModel) // ✅ Providing AuthViewModel to All Views
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
        MainView()
            .environmentObject(AuthViewModel())
    }
}
