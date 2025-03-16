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
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 60)
            
            // Login Form
            VStack(spacing: 20) {
                InputField(title: "EMAIL", text: $email)
                InputField(title: "PASSWORD", text: $password, isSecure: true)
                
                // Forgot Password
                Button(action: {
                    shouldShowForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.primaryBlack)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 8)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Login Button and Sign Up Link
            VStack(spacing: 16) {
                Button(action: {
                    authViewModel.signIn(email: email, password: password)
                }) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlack)
                        .cornerRadius(12)
                }
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button(action: {
                        shouldShowSignUp = true
                    }) {
                        Text("Sign Up")
                            .fontWeight(.medium)
                            .foregroundColor(.primaryBlack)
                    }
                }
                .font(.subheadline)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $shouldShowSignUp) {
            SignUpView()
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
} 