//
//  ProfilePageView.swift
//  Smart Locker
//
//  Created by Oğuzhan Sönmeztürk on 20.03.2025.
//

import SwiftUI
import PhotosUI
import Kingfisher

// Import Profile views directly (they're in a different directory)
// import SwiftUI // This is redundant, removing

struct ProfilePageView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    @State private var showUpdateEmail = false
    @State private var showUpdatePassword = false
    @State private var showRentalHistory = false
    @State private var showActiveRentals = false
    
    // State for photo picker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(AppColors.primaryBlack)
                                .imageScale(.large)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Profile Header
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Group {
                                if let profileUrlString = authViewModel.currentUser?.profileImageUrl, let url = URL(string: profileUrlString) {
                                    KFImage(url)
                                        .placeholder { // Placeholder while loading or if URL is invalid
                                            Image("profile_placeholder")
                                                .resizable()
                                                .scaledToFill()
                                        }
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image("profile_placeholder") // Default placeholder
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.primaryBlack, lineWidth: 3))
                            .shadow(color: AppColors.primaryYellow.opacity(0.3), radius: 10)
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                        authViewModel.updateProfileImage(image: uiImage)
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Settings Sections
                    VStack(spacing: 24) {
                        // Account Section
                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "wallet.pass.fill", title: "Balance", value: "$200.00")
                            
                            NavigationLink {
                                Text("QR Code Screen")
                            } label: {
                                SettingsRow(icon: "qrcode", title: "Current Locker")
                            }
                            
                            Button(action: {
                                showUpdateEmail = true
                            }) {
                                SettingsRow(icon: "envelope.fill", title: "Update Email")
                            }
                            
                            Button(action: {
                                showUpdatePassword = true
                            }) {
                                SettingsRow(icon: "key.fill", title: "Update Password")
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            SettingsRow(icon: "moon.fill", title: "Dark Mode") {
                                Toggle("", isOn: $isDarkMode)
                                    .tint(AppColors.primaryYellow)
                            }
                            
                            NavigationLink {
                                Text("Notifications Settings")
                            } label: {
                                SettingsRow(icon: "bell.fill", title: "Notifications")
                            }
                        }
                        
                        // Bookings Section
                        SettingsSection(title: "Bookings") {
                            Button(action: {
                                showActiveRentals = true
                            }) {
                                SettingsRow(icon: "calendar", title: "Active Rentals", value: "\(reservationViewModel.currentRentalCount)")
                            }
                            
                            Button(action: {
                                showRentalHistory = true
                            }) {
                                SettingsRow(icon: "clock.fill", title: "Rental History", value: "\(reservationViewModel.pastRentalCount)")
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        authViewModel.signOut()
                        dismiss()
                    }) {
                        HStack {
                            Text("Sign Out")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryBlack)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primaryBlack.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showUpdateEmail) {
                UpdateEmailView()
                    .environmentObject(authViewModel)
            }
            .fullScreenCover(isPresented: $showUpdatePassword) {
                UpdatePasswordView()
                    .environmentObject(authViewModel)
            }
            .fullScreenCover(isPresented: $showRentalHistory) {
                RentalHistoryView()
                    .environmentObject(reservationViewModel)
            }
            .fullScreenCover(isPresented: $showActiveRentals) {
                ActiveRentalsView()
                    .environmentObject(reservationViewModel)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            // This is a good place to fetch user data if it might be stale,
            // though AuthViewModel already fetches on auth state change.
            // If an error occurs during image upload, display it.
            // Consider adding an alert to show authViewModel.errorMessage if it's not nil.
        }
        // Add an alert to display errors from AuthViewModel
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                authViewModel.errorMessage = nil // Clear the error message
            }
        }, message: {
            Text(authViewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(16)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String?
    var trailingContent: AnyView?
    
    init(
        icon: String,
        title: String,
        value: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trailingContent = nil
    }
    
    init<V: View>(
        icon: String,
        title: String,
        @ViewBuilder trailingContent: () -> V
    ) {
        self.icon = icon
        self.title = title
        self.value = nil
        self.trailingContent = AnyView(trailingContent())
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primaryBlack)
                .frame(width: 32)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.gray)
            }
            
            if let trailingContent = trailingContent {
                trailingContent
            }
            
            if trailingContent == nil && value == nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// ✅ Preview with Mock Data
struct ProfilePageView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = User(
            id: "preview-user",
            name: "John Doe",
            email: "john@example.com",
            profileImageUrl: nil
        )
        
        let mockReservationViewModel = ReservationViewModel()
        
        return ProfilePageView()
            .environmentObject(mockAuthViewModel)
            .environmentObject(mockReservationViewModel)
    }
}
