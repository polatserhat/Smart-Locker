import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
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
            
            VStack(alignment: .leading, spacing: 32) {
                Text("Create new\nAccount")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Please fill in the form to continue")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                CompactInputField(title: "NAME", text: $name, keyboardType: .namePhonePad)
                CompactInputField(title: "EMAIL", text: $email, keyboardType: .emailAddress)
                CompactInputField(title: "PASSWORD", text: $password, isSecure: true)
            }
            .padding(.top, 16)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    authViewModel.signUp(
                        name: name,
                        email: email,
                        password: password,
                        profileImage: nil
                    )
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondary)
                .cornerRadius(12)
                .disabled(authViewModel.isLoading)
                
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(AppColors.textSecondary)
                        Text("Sign In")
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
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
} 
