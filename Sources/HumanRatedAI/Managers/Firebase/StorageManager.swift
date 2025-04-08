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
    /// Delete a file from Firebase Storage using a URL
    /// - Parameter url: file URL used to access the file
    public func deleteFileFromURL(_ url: URL) async throws {
        // Get a direct reference to the file using the URL
        let fileRef = try storage.reference(for: url)
        // Delete the file
        try await fileRef.delete()
    }
    
    /// Download data from Firebase Storage
    /// - Parameter path: The storage path to the file
    /// - Returns: The downloaded data
    public func downloadData(from path: String, retryCount: Int = 2) async throws -> Data {
        var lastError: Error?
        for attempt in 0...retryCount {
            do {
                let fileRef = storageRef.child(path)
                let maxSize: Int64 = 50 * 1024 * 1024 // 50MB max size
                // Create a task with a timeout
                let downloadTask = Task<Data, Error> {
#if os(Android)
                    return try await fileRef.getDataAsync(maxSize: maxSize)
#else
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
                // Create a timeout task
                let timeoutTask = Task<Void, Never> {
                    try? await Task.sleep(nanoseconds: UInt64(15 * 1_000_000_000))
                    downloadTask.cancel()
                }
                do {
                    // Wait for the download to complete
                    let data = try await downloadTask.value
                    // Success - cancel the timeout and return the data
                    timeoutTask.cancel()
                    return data
                } catch {
                    // Cancel the timeout task since we're handling the error
                    timeoutTask.cancel()
                    // Rethrow the error to be handled by the outer catch
                    throw error
                }
            } catch {
                // Check if the task was cancelled (timeout)
                if Task.isCancelled || error is CancellationError {
                    throw NSError(domain: "StorageError",
                                  code: 408,
                                  userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
                }
                // Store the error for potential retries
                lastError = error
                // Wait before retry if we're not on the last attempt
                if attempt < retryCount {
                    // Use exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (attempt + 1)))
                }
            }
        }
        // If we've exhausted all retries, throw the last error
        throw lastError ?? NSError(domain: "StorageError",
                                   code: 500,
                                   userInfo: [NSLocalizedDescriptionKey: "Unknown error during download"])
    }
    
    /// Get download URL for a file in Firebase Storage
    /// - Parameter path: The storage path to the file
    /// - Returns: The download URL
    public func getDownloadURL(for path: String) async throws -> URL {
        let fileRef = storageRef.child(path)
        return try await fileRef.downloadURL()
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
        _ = try await fileRef.putDataAsync(data, metadata: uploadMetadata)
        
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
}

// MARK: - Utility Methods
extension StorageManager {
    /// Extract file name from a storage path
    /// - Parameter path: The storage path
    /// - Returns: File name
    public func fileNameFromPath(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        return components.last ?? path
    }
    
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
    
    /// Checks if the image is uploaded by the user (has path with "/users/{userID}/ai_settings/" and ending with ".jpg", ".jpeg", or ".png")
    /// - Parameters:
    ///   - url: the url to check
    ///   - userID: user ID to check against
    /// - Returns: true if the image is uploaded by the user
    public func isUserUploadedImage(_ url: URL, userID: String) -> Bool {
        let path = url.path
        return path.contains("/users/\(userID)/ai_settings/") &&
        (path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png"))
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
