import SwiftUI

struct UpdateEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var newEmail: String = ""
    @State private var password: String = ""
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
                    
                    Text("Update Email")
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
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.secondary)
                            .padding()
                            .background(AppColors.secondary.opacity(0.15))
                            .clipShape(Circle())
                        
                        Text("Change your email address")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Current email: \(authViewModel.currentUser?.email ?? "Not available")")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Email Address")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("example@email.com", text: $newEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
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
                            Text("Current Password for Verification")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            SecureField("Enter your password", text: $password)
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
                            updateEmail()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            } else {
                                Text("Update Email")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.secondary)
                        .cornerRadius(8)
                        .padding(.top, 12)
                        .disabled(newEmail.isEmpty || password.isEmpty || isLoading)
                        .opacity((newEmail.isEmpty || password.isEmpty || isLoading) ? 0.6 : 1.0)
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
    
    private func updateEmail() {
        isLoading = true
        
        // Use the AuthViewModel method to update email
        authViewModel.updateUserEmail(newEmail: newEmail, currentPassword: password) { success, errorMsg in
            if success {
                // Clear the form
                self.newEmail = ""
                self.password = ""
                // Dismiss the view on success
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
            
            self.isLoading = false
        }
    }
}

struct UpdateEmailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = User(
            id: "preview-user", 
            name: "John Doe", 
            email: "john@example.com",
            profileImageUrl: nil
        )
        
        return UpdateEmailView()
            .environmentObject(mockAuthViewModel)
            .preferredColorScheme(.dark)
    }
} 
