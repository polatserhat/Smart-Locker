import SwiftUI

struct UpdatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Update Password")
                    .font(.headline)
                
                Spacer()
                
                Color.clear
                    .frame(width: 24)
            }
            .padding(.horizontal, 20)
            
            // Content
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 60)
                
                // Key icon
                Image(systemName: "key.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Circle())
                
                Text("Change your password")
                    .font(.headline)
                
                Text("Your password must be at least 8 characters...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                    .frame(height: 30)
                
                // Form fields
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter your current password", text: $currentPassword)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter your new password", text: $newPassword)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            updatePassword()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Update Password")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray)
                        .cornerRadius(8)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.top)
    }
    
    private func updatePassword() {
        isLoading = true
        
        // Use the AuthViewModel method to update password
        authViewModel.updateUserPassword(currentPassword: currentPassword, newPassword: newPassword) { success, errorMsg in
            if success {
                // Clear the form
                self.currentPassword = ""
                self.newPassword = ""
            }
            
            self.isLoading = false
        }
    }
}

struct UpdatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        UpdatePasswordView()
            .environmentObject(AuthViewModel())
    }
} 