// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  StorageManager.swift
//  human-rated-ai
//
//  Created on 3/30/25.
//

#if os(Android)
import SkipFirebaseStorage
#else
import FirebaseStorage
#endif
import SwiftUI

public class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    private let storage: Storage
    private let storageRef: StorageReference
    
    private init() {
        self.storage = Storage.storage()
        self.storageRef = storage.reference()
    }
}

// MARK: - Public Methods
extension StorageManager {
    /// Upload data to Firebase Storage
    /// - Parameters:
    ///   - data: The data to upload
    ///   - path: The storage path (e.g., "users/userId/images/profile.jpg")
    ///   - metadata: Optional metadata for the file
    /// - Returns: Download URL for the uploaded file
    public func uploadData(_ data: Data, to path: String, metadata: StorageMetadata? = nil) async throws -> URL {
        let fileRef = storageRef.child(path)
        let uploadMetadata = metadata ?? StorageMetadata()
        
        // Perform the upload using the Skip-compatible method
        let resultMetadata = try await fileRef.putDataAsync(data, metadata: uploadMetadata)
        
        // Get the download URL
        return try await fileRef.downloadURL()
    }
    
    /// Upload an image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - path: The storage path (e.g., "users/userId/images/profile.jpg")
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Download URL for the uploaded image
    public func uploadImage(_ image: UIImage, to path: String, compressionQuality: CGFloat = 0.8) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw NSError(domain: "StorageError",
                          code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await uploadData(imageData, to: path, metadata: metadata)
    }
    
    /// Download data from Firebase Storage
    /// - Parameter path: The storage path to the file
    /// - Returns: The downloaded data
    public func downloadData(from path: String) async throws -> Data {
        let fileRef = storageRef.child(path)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB max size
        
#if os(Android)
        // Android (Skip) implementation uses getDataAsync
        return try await fileRef.getDataAsync(maxSize: maxSize)
#else
        // iOS native implementation uses data(maxSize:)
        return try await withCheckedThrowingContinuation { continuation in
            fileRef.getData(maxSize: maxSize) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    let noDataError = NSError(domain: "StorageError",
                                              code: 404,
                                              userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                    continuation.resume(throwing: noDataError)
                }
            }
        }
#endif
    }
    
    /// Get download URL for a file in Firebase Storage
    /// - Parameter path: The storage path to the file
    /// - Returns: The download URL
    public func getDownloadURL(for path: String) async throws -> URL {
        let fileRef = storageRef.child(path)
        return try await fileRef.downloadURL()
    }
    
    /// Delete a file from Firebase Storage
    /// - Parameter path: The storage path to the file
    public func deleteFile(at path: String) async throws {
        let fileRef = storageRef.child(path)
        try await fileRef.delete()
    }
    
    /// Get metadata for a file
    /// - Parameter path: The storage path to the file
    /// - Returns: The metadata for the file
    public func getMetadata(for path: String) async throws -> StorageMetadata {
        let fileRef = storageRef.child(path)
        return try await fileRef.getMetadata()
    }
    
    /// Update metadata for a file
    /// - Parameters:
    ///   - metadata: The metadata to update
    ///   - path: The storage path to the file
    /// - Returns: The updated metadata
    public func updateMetadata(_ metadata: StorageMetadata, for path: String) async throws -> StorageMetadata {
        let fileRef = storageRef.child(path)
        return try await fileRef.updateMetadata(metadata)
    }
}

// MARK: - Utility Methods
extension StorageManager {
    /// Generate a unique file path for user uploads
    /// - Parameters:
    ///   - userID: User identifier
    ///   - fileType: Type of file (e.g., "images", "videos", "audio")
    ///   - fileExtension: File extension (e.g., "jpg", "mp4", "mp3")
    /// - Returns: A unique file path
    public func generateUniqueFilePath(for userID: String, fileType: String, fileExtension: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomComponent = UUID().uuidString.prefix(8)
        return "users/\(userID)/\(fileType)/\(timestamp)_\(randomComponent).\(fileExtension)"
    }
    
    /// Extract file name from a storage path
    /// - Parameter path: The storage path
    /// - Returns: File name
    public func fileNameFromPath(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        return components.last ?? path
    }
}

// MARK: - Error Handling
extension StorageManager {
    /// Handle storage errors in a user-friendly way
    /// - Parameter error: The error to handle
    /// - Returns: A user-friendly error message
    public func handleStorageError(_ error: Error) -> String {
        // Simply return the localized description as the Skip implementation
        // doesn't provide the same error code mapping as iOS
        return error.localizedDescription
    }
}
