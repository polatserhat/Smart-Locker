import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isAuthenticated = user != nil
                if let user = user {
                    self.fetchUserData(userId: user.uid)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        // Validate input
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = self.handleAuthError(error)
                }
            }
        }
    }
    
    func signUp(name: String, email: String, password: String, profileImage: UIImage? = nil) {
        // Validate input
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            return
        }
        
        guard isValidPassword(password) else {
            errorMessage = "Password must be at least 6 characters long"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = self.handleAuthError(error)
                    return
                }
                
                guard let userId = result?.user.uid else {
                    self.isLoading = false
                    self.errorMessage = "Failed to create account"
                    return
                }
                
                // Update display name
                let changeRequest = self.auth.currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges { [weak self] error in
                    if let error = error {
                        print("Failed to update display name: \(error.localizedDescription)")
                    }
                }
                
                // Create user profile in Firestore
                self.createUserProfile(userId: userId, name: name, email: email)
            }
        }
    }
    
    private func createUserProfile(userId: String, name: String, email: String) {
        let userData: [String: Any] = [
            "id": userId,
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        firestore.collection("users").document(userId).setData(userData) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                } else {
                    self.currentUser = User(
                        id: userId,
                        name: name,
                        email: email,
                        profileImageUrl: nil
                    )
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    func fetchUserData(userId: String) {
        firestore.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let name = data["name"] as? String,
                  let email = data["email"] as? String else {
                print("Invalid or missing user data in Firestore")
                return
            }
            
            DispatchQueue.main.async {
                self.currentUser = User(
                    id: userId,
                    name: name,
                    email: email,
                    profileImageUrl: nil
                )
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Simplified password validation: minimum 6 characters
        return password.count >= 6
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let authError = error as NSError
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid email or password"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters long"
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found. Please sign up"
        default:
            return "An error occurred. Please try again"
        }
    }
}

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    var profileImageUrl: String?
} 