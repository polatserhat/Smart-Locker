import Foundation
import FirebaseStorage
import UIKit // For UIImage

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()

    private init() {}

    enum StorageError: Error {
        case imageDataConversionFailed
        case uploadFailed(Error)
        case getDownloadURLFailed(Error)
        case unknown
    }

    func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<URL, StorageError>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            completion(.failure(.imageDataConversionFailed))
            return
        }

        let imageRef = storage.child("profile_images/\(userId).jpg")

        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(.uploadFailed(error)))
                return
            }

            guard metadata != nil else {
                completion(.failure(.unknown))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(.getDownloadURLFailed(error)))
                    return
                }
                guard let downloadURL = url else {
                    completion(.failure(.unknown))
                    return
                }
                completion(.success(downloadURL))
            }
        }
    }
} 