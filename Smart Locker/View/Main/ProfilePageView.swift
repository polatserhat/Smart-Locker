//
//  ProfilePageView.swift
//  Smart Locker
//
//  Created by Oğuzhan Sönmeztürk on 20.03.2025.
//

import SwiftUI

struct ProfilePageView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
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
                        Image("profile_placeholder")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.primaryBlack, lineWidth: 3))
                            .shadow(color: AppColors.primaryYellow.opacity(0.3), radius: 10)
                        
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
                                SettingsRow(icon: "qrcode", title: "QR Code")
                            }
                            
                            NavigationLink {
                                Text("Password Change Screen")
                            } label: {
                                SettingsRow(icon: "key.fill", title: "Change Password")
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
                            NavigationLink {
                                Text("Active Reservations")
                            } label: {
                                SettingsRow(icon: "calendar", title: "Active Reservations", value: "2")
                            }
                            
                            NavigationLink {
                                Text("Booking History")
                            } label: {
                                SettingsRow(icon: "clock.fill", title: "History")
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
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
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
        
        return ProfilePageView()
            .environmentObject(mockAuthViewModel)
    }
}
