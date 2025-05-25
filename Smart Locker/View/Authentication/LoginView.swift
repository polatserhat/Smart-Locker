import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var shouldShowForgotPassword = false
    @State private var shouldShowSignUp = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome\nBack!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 60)
            
            // Login Form
            VStack(spacing: 12) {
                CompactInputField(title: "EMAIL", text: $email, keyboardType: .emailAddress)
                CompactInputField(title: "PASSWORD", text: $password, isSecure: true)
                
                // Forgot Password
                Button(action: {
                    shouldShowForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 4)
            }
            .padding(.top, 32)
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Login Button and Sign Up Link
            VStack(spacing: 16) {
                Button(action: {
                    authViewModel.signIn(email: email, password: password)
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.secondary)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading)
                
                // Sign Up Link
                Button(action: {
                    shouldShowSignUp = true
                }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(AppColors.textSecondary)
                        Text("Sign Up")
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.secondary)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $shouldShowSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
    }
}

// Compact Input Field for Login/SignUp
struct CompactInputField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isFocused ? AppColors.secondary : AppColors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            ZStack {
                // Background with border
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surface)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? AppColors.secondary : AppColors.textSecondary.opacity(0.2), lineWidth: isFocused ? 1.5 : 0.8)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )
                
                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                        .padding(.horizontal, 12)
                        .foregroundColor(AppColors.textPrimary)
                        .focused($isFocused)
                        .font(.system(size: 16))
                        .keyboardType(keyboardType)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                        .padding(.horizontal, 12)
                        .foregroundColor(AppColors.textPrimary)
                        .focused($isFocused)
                        .font(.system(size: 16))
                        .keyboardType(keyboardType)
                }
            }
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
} 
