import SwiftUI

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
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            } else {
                TextField("", text: $text)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        InputField(title: "EMAIL", text: .constant(""))
        InputField(title: "PASSWORD", text: .constant(""), isSecure: true)
    }
    .padding()
} 