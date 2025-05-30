import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var navigateToHome = false
    
    // Add a static shared instance
    static var shared: AuthViewModel?
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
        // Set the shared instance if it doesn't exist
        if AuthViewModel.shared == nil {
            AuthViewModel.shared = self
        }
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
                print("Invalid or missing user data in Firestore for userId: \(userId)")
                return
            }
            
            // Fetch the profileImageUrl from the snapshot
            let profileImageUrl = data["profileImageUrl"] as? String
            
            DispatchQueue.main.async {
                self.currentUser = User(
                    id: userId,
                    name: name,
                    email: email,
                    profileImageUrl: profileImageUrl
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
    
    // Add methods for updating user profile data
    
    func updateUserEmail(newEmail: String, currentPassword: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser, let currentEmail = user.email else {
            completion(false, "User not logged in")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Re-authenticate the user first
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    let errorMessage = "Authentication failed: \(error.localizedDescription)"
                    self.errorMessage = errorMessage
                    completion(false, errorMessage)
                }
                return
            }
            
            // Now update the email
            user.updateEmail(to: newEmail) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        let errorMessage = "Failed to update email: \(error.localizedDescription)"
                        self.errorMessage = errorMessage
                        completion(false, errorMessage)
                    }
                    return
                }
                
                // Update Firestore user document
                if let userId = self.currentUser?.id {
                    self.firestore.collection("users").document(userId).updateData([
                        "email": newEmail,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]) { error in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            if let error = error {
                                let errorMessage = "Failed to update profile: \(error.localizedDescription)"
                                self.errorMessage = errorMessage
                                completion(false, errorMessage)
                            } else {
                                // Update local user object
                                if let currentUser = self.currentUser {
                                    let updatedUser = User(
                                        id: currentUser.id,
                                        name: currentUser.name,
                                        email: newEmail,
                                        profileImageUrl: currentUser.profileImageUrl
                                    )
                                    self.currentUser = updatedUser
                                }
                                completion(true, nil)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    func updateUserPassword(currentPassword: String, newPassword: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(false, "User not logged in")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Re-authenticate the user first
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    let errorMessage = "Authentication failed: \(error.localizedDescription)"
                    self.errorMessage = errorMessage
                    completion(false, errorMessage)
                }
                return
            }
            
            // Now update the password
            user.updatePassword(to: newPassword) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        let errorMessage = "Failed to update password: \(error.localizedDescription)"
                        self.errorMessage = errorMessage
                        completion(false, errorMessage)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
    }

    // New function to update profile image
    func updateProfileImage(image: UIImage) {
        guard let userId = currentUser?.id else {
            errorMessage = "User not found."
            return
        }

        isLoading = true
        errorMessage = nil

        StorageService.shared.uploadProfileImage(image, userId: userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let url):
                    let profileImageUrlString = url.absoluteString
                    self.firestore.collection("users").document(userId).updateData(["profileImageUrl": profileImageUrlString]) { error in
                        if let error = error {
                            self.errorMessage = "Failed to update profile image in Firestore: \(error.localizedDescription)"
                        } else {
                            self.currentUser?.profileImageUrl = profileImageUrlString
                        }
                    }
                case .failure(let error):
                    // Handle specific StorageService errors if needed, or a generic message
                    switch error {
                    case .imageDataConversionFailed:
                        self.errorMessage = "Failed to prepare image for upload."
                    case .uploadFailed(let err):
                        self.errorMessage = "Image upload failed: \(err.localizedDescription). Check Firebase Storage rules."
                    case .getDownloadURLFailed(let err):
                        self.errorMessage = "Failed to get image URL: \(err.localizedDescription)."
                    default:
                        self.errorMessage = "An unknown error occurred while uploading the image."
                    }
                }
            }
        }
    }
}

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    var profileImageUrl: String?
} 