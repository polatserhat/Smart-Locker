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
                print("Auth state changed. User: \(user?.uid ?? "nil")")
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
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Sign in error: \(error.localizedDescription)")
                    self.errorMessage = self.handleAuthError(error)
                } else {
                    print("Sign in successful")
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    func signUp(name: String, email: String, password: String, profileImage: UIImage? = nil) {
        guard isValidPassword(password) else {
            errorMessage = "Password must be at least 8 characters long and contain at least one uppercase letter, one number, and one special character"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("Starting sign up process for email: \(email)")
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    print("Sign up error: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = self.handleAuthError(error)
                }
                return
            }
            
            guard let userId = result?.user.uid else {
                DispatchQueue.main.async {
                    print("Failed to get user ID after creation")
                    self.isLoading = false
                    self.errorMessage = "User ID not found after registration"
                }
                return
            }
            
            print("User created successfully with ID: \(userId)")
            
            // Update Firebase Auth Profile with Display Name
            let changeRequest = self.auth.currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = name
            changeRequest?.commitChanges { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Failed to update display name: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    }
                } else {
                    print("Display name updated successfully")
                }
            }
            
            // Store User in Firestore
            self.createUserProfile(userId: userId, name: name, email: email)
        }
    }
    
    private func createUserProfile(userId: String, name: String, email: String) {
        print("Creating user profile in Firestore for user: \(userId)")
        
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        firestore.collection("users").document(userId).setData(userData) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to store user data: \(error.localizedDescription)"
                } else {
                    print("User profile created successfully in Firestore")
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
        print("Fetching user data for ID: \(userId)")
        
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
            
            print("User data fetched successfully")
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
            print("User signed out successfully")
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*])(?=.{8,})"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let authError = error as NSError
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email is already in use."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak."
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found. Please sign up."
        default:
            return error.localizedDescription
        }
    }
}

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    var profileImageUrl: String?
} 