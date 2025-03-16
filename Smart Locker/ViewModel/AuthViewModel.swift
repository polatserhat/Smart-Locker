import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func signIn(email: String, password: String) {
        // TODO: Implement Firebase Authentication
        // For MVP, we'll just set isAuthenticated to true
        isAuthenticated = true
    }
    
    func signUp(name: String, email: String, password: String) {
        // TODO: Implement Firebase Authentication
        // For MVP, we'll just set isAuthenticated to true
        isAuthenticated = true
    }
    
    func signOut() {
        // TODO: Implement Firebase Authentication
        isAuthenticated = false
        currentUser = nil
    }
}

struct User {
    let id: String
    let name: String
    let email: String
    var profileImageUrl: String?
} 