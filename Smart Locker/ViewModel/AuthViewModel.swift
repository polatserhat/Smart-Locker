import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let storage = Storage.storage()
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
                    self.errorMessage = self.handleAuthError(error)
                } else if let userId = result?.user.uid {
                    self.fetchUserData(userId: userId)
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
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = self.handleAuthError(error)
                }
                return
            }
            
            guard let userId = result?.user.uid else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create user"
                }
                return
            }
            
            // Upload profile image if provided
            if let image = profileImage {
                self.uploadProfileImage(image, userId: userId) { imageUrl in
                    self.createUserProfile(userId: userId, name: name, email: email, profileImageUrl: imageUrl)
                }
            } else {
                self.createUserProfile(userId: userId, name: name, email: email, profileImageUrl: nil)
            }
        }
    }
    
    private func createUserProfile(userId: String, name: String, email: String, profileImageUrl: String?) {
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "profileImageUrl": profileImageUrl as Any,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        firestore.collection("users").document(userId).setData(userData) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.currentUser = User(
                        id: userId,
                        name: name,
                        email: email,
                        profileImageUrl: profileImageUrl
                    )
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storageRef = storage.reference().child("users/\(userId)/profile.jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
    
    func fetchUserData(userId: String) {
        firestore.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let name = data["name"] as? String,
                  let email = data["email"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.currentUser = User(
                    id: userId,
                    name: name,
                    email: email,
                    profileImageUrl: data["profileImageUrl"] as? String
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