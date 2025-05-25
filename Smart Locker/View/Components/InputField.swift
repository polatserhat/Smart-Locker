import SwiftUI

struct InputField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isFocused ? AppColors.secondary : AppColors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            ZStack {
                // Background with border
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? AppColors.secondary : AppColors.textSecondary.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )
                    .shadow(color: isFocused ? AppColors.secondary.opacity(0.2) : Color.clear, radius: isFocused ? 4 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .foregroundColor(AppColors.textPrimary)
                        .focused($isFocused)
                        .font(.body)
                        .keyboardType(keyboardType)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .foregroundColor(AppColors.textPrimary)
                        .focused($isFocused)
                        .font(.body)
                        .keyboardType(keyboardType)
                }
            }
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(Double.random(in: 0...0.3))) {
                isAnimating = true
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