import SwiftUI

/// AppTheme manages the global theme configuration for the app.
/// It provides helpers to apply consistent styling across the app.
struct AppTheme {
    // Apply dark mode to a view
    static func applyDarkMode<T: View>(_ view: T) -> some View {
        view.preferredColorScheme(.dark)
    }
    
    // Button styles
    struct ButtonStyles {
        // Primary button style - used for main actions
        static func primary<T: View>(_ content: T) -> some View {
            content
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondary)
                .cornerRadius(12)
        }
        
        // Secondary button style - used for secondary actions
        static func secondary<T: View>(_ content: T) -> some View {
            content
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.surfaceSecondary)
                .cornerRadius(12)
        }
        
        // Outline button style - used for less prominent actions
        static func outline<T: View>(_ content: T) -> some View {
            content
                .foregroundColor(AppColors.secondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
        }
    }
    
    // Card styles for consistent card appearances
    struct CardStyles {
        // Standard card style
        static func standard<T: View>(_ content: T) -> some View {
            content
                .padding()
                .background(AppColors.surface)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        // Elevated card with more prominence
        static func elevated<T: View>(_ content: T) -> some View {
            content
                .padding()
                .background(AppColors.surface)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
    }
    
    // Text styles for consistent typography
    struct TextStyles {
        // Title style
        static func title(_ text: String) -> some View {
            Text(text)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
        }
        
        // Heading style
        static func heading(_ text: String) -> some View {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
        
        // Body text style
        static func body(_ text: String) -> some View {
            Text(text)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
        }
        
        // Caption style
        static func caption(_ text: String) -> some View {
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
} 