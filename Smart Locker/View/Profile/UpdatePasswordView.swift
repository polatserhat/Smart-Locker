import SwiftUI

struct UpdatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - at the very top
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(AppColors.textPrimary)
                            .imageScale(.large)
                    }
                    
                    Spacer()
                    
                    Text("Update Password")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .frame(height: 80)
                
                // Content - centered in remaining space
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon and title section
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.secondary)
                            .padding()
                            .background(AppColors.secondary.opacity(0.15))
                            .clipShape(Circle())
                        
                        Text("Change your password")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Your password must be at least 8 characters")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            SecureField("Enter your current password", text: $currentPassword)
                                .padding()
                                .background(AppColors.surface)
                                .foregroundColor(AppColors.textPrimary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            SecureField("Enter your new password", text: $newPassword)
                                .padding()
                                .background(AppColors.surface)
                                .foregroundColor(AppColors.textPrimary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            updatePassword()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            } else {
                                Text("Update Password")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.secondary)
                        .cornerRadius(8)
                        .padding(.top, 12)
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || newPassword.count < 8 || isLoading)
                        .opacity((currentPassword.isEmpty || newPassword.isEmpty || newPassword.count < 8 || isLoading) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        // Add alert for error messages
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                authViewModel.errorMessage = nil
            }
        }, message: {
            Text(authViewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
    
    private func updatePassword() {
        isLoading = true
        
        // Use the AuthViewModel method to update password
        authViewModel.updateUserPassword(currentPassword: currentPassword, newPassword: newPassword) { success, errorMsg in
            if success {
                // Clear the form
                self.currentPassword = ""
                self.newPassword = ""
                // Dismiss the view on success
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
            
            self.isLoading = false
        }
    }
}

struct UpdatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        UpdatePasswordView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
} 
