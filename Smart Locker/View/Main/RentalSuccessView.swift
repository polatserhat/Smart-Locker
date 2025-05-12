import SwiftUI

struct RentalSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldDismissToRoot = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryYellow)
                .padding(.top, 60)
            
            // Success Message
            VStack(spacing: 16) {
                Text("Rental Started!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your locker is now available for use. The clock has started, and you'll only be charged for the time you actually use.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Return to Home Button
            Button(action: {
                // This will trigger the full dismissal chain
                shouldDismissToRoot = true
                NotificationCenter.default.post(name: NSNotification.Name("DismissToRoot"), object: nil)
                dismiss()
            }) {
                Text("RETURN TO HOME")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
    }
} 