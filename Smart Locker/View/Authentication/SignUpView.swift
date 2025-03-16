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
                        .foregroundColor(.primaryBlack)
                        .imageScale(.large)
                }
                Spacer()
            }
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 32) {
                Text("Create new\nAccount")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please fill in the form to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                InputField(title: "NAME", text: $name)
                InputField(title: "EMAIL", text: $email)
                InputField(title: "PASSWORD", text: $password, isSecure: true)
            }
            .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    authViewModel.signUp(name: name, email: email, password: password)
                }) {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlack)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Text("Sign In")
                            .fontWeight(.medium)
                            .foregroundColor(.primaryBlack)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            if isSecure {
                SecureField("", text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
            } else {
                TextField("", text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray6))
            )
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
} 
