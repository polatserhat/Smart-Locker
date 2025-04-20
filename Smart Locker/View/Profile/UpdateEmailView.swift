import SwiftUI

struct UpdateEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var newEmail: String = ""
    @State private var password: String = ""
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
                
                Text("Update Email")
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
                
                // Email icon
                Image(systemName: "envelope.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Circle())
                
                Text("Change your email address")
                    .font(.headline)
                
                Text("Your current email: Not available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                    .frame(height: 30)
                
                // Form fields
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Email Address")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("example@email.com", text: $newEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password for Verification")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter your password", text: $password)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            updateEmail()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Update Email")
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
    
    private func updateEmail() {
        isLoading = true
        
        // Use the AuthViewModel method to update email
        authViewModel.updateUserEmail(newEmail: newEmail, currentPassword: password) { success, errorMsg in
            if success {
                // Clear the form
                self.newEmail = ""
                self.password = ""
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
    }
} 
