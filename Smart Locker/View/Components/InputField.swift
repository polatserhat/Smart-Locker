import SwiftUI

struct InputField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            if isSecure {
                SecureField("", text: $text)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(10)
                    .foregroundColor(AppColors.textPrimary)
            } else {
                TextField("", text: $text)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(10)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.surface)
            .cornerRadius(10)
            .foregroundColor(AppColors.textPrimary)
    }
}

#Preview {
    VStack(spacing: 20) {
        InputField(title: "EMAIL", text: .constant(""))
        InputField(title: "PASSWORD", text: .constant(""), isSecure: true)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
} 