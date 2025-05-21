import SwiftUI
import UIKit

struct AppColors {
    // Main colors
    static let primary = Color("DarkPrimary") // Dark background
    static let secondary = Color("DarkAccent") // Accent color
    static let background = Color("DarkBackground") // Even darker background
    
    // Text colors
    static let textPrimary = Color("TextPrimary") // Light text
    static let textSecondary = Color("TextSecondary") // Dimmed text
    
    // UI elements
    static let surface = Color("Surface") // Slightly lighter than background for cards
    static let surfaceSecondary = Color("SurfaceSecondary") // Alternative surface color
    static let divider = Color("Divider") // Color for dividers
    
    // Semantic colors
    static let success = Color("Success") // Green for success states
    static let error = Color("Error") // Red for errors
    static let warning = Color("Warning") // Yellow for warnings
    
    // Helper function to get color value
    static func getColor(_ name: String) -> Color {
        return Color(name)
    }
}

// Usage example:
// Text("Hello")
//     .foregroundColor(AppColors.primary)
//     .background(AppColors.background) 