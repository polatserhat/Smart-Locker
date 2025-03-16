import SwiftUI
import PhotosUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
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
            
            VStack(alignment: .leading, spacing: 32) {
                Text("Create new\nAccount")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please fill in the form to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Profile Picture Selection
            VStack(spacing: 12) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.primaryYellow, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Text("Select Profile Picture")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primaryYellow)
                }
            }
            .onChange(of: photoPickerItem) { _ in
                Task {
                    if let data = try? await photoPickerItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            
            VStack(spacing: 20) {
                InputField(title: "NAME", text: $name)
                InputField(title: "EMAIL", text: $email)
                InputField(title: "PASSWORD", text: $password, isSecure: true)
            }
            .padding(.top, 20)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    authViewModel.signUp(
                        name: name,
                        email: email,
                        password: password,
                        profileImage: selectedImage
                    )
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primaryBlack)
                .cornerRadius(12)
                .disabled(authViewModel.isLoading)
                
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Text("Sign In")
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primaryBlack)
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

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
} 
