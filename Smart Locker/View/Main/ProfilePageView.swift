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
    @State private var localProfileImage: UIImage? = nil
    
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
                                .foregroundColor(AppColors.textPrimary)
                                .imageScale(.large)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Profile Header
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Group {
                                if let localImage = localProfileImage {
                                    Image(uiImage: localImage)
                                        .resizable()
                                        .scaledToFill()
                                } else if let profileUrlString = authViewModel.currentUser?.profileImageUrl, let url = URL(string: profileUrlString) {
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
                            .overlay(Circle().stroke(AppColors.secondary, lineWidth: 3))
                            .shadow(color: AppColors.secondary.opacity(0.3), radius: 10)
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                        // Save to UserDefaults
                                        saveImageToUserDefaults(uiImage)
                                        // Update local state
                                        localProfileImage = uiImage
                                        // Also update Firebase when it's available
                                        authViewModel.updateProfileImage(image: uiImage)
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
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
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.secondary)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(AppColors.background)
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
        .onAppear {
            // Load profile image from UserDefaults when view appears
            loadImageFromUserDefaults()
            
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
    
    // MARK: - UserDefaults Helper Methods
    
    private func saveImageToUserDefaults(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(imageData, forKey: "userProfileImage")
            
            // If we have a user ID, also store it with that key for multi-user support
            if let userId = authViewModel.currentUser?.id {
                UserDefaults.standard.set(imageData, forKey: "userProfileImage_\(userId)")
            }
            
            // Post notification that profile image was updated
            NotificationCenter.default.post(name: NSNotification.Name("ProfileImageUpdated"), object: nil)
        }
    }
    
    private func loadImageFromUserDefaults() {
        // First try user-specific image if we have a user ID
        if let userId = authViewModel.currentUser?.id, 
           let imageData = UserDefaults.standard.data(forKey: "userProfileImage_\(userId)"),
           let image = UIImage(data: imageData) {
            localProfileImage = image
            return
        }
        
        // Fall back to generic key
        if let imageData = UserDefaults.standard.data(forKey: "userProfileImage"),
           let image = UIImage(data: imageData) {
            localProfileImage = image
        }
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
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content()
            }
            .background(AppColors.surface)
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
                .foregroundColor(AppColors.secondary)
                .frame(width: 32)
            
            Text(title)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if let trailingContent = trailingContent {
                trailingContent
            }
            
            if trailingContent == nil && value == nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.surface)
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
            .preferredColorScheme(.dark)
    }
}
