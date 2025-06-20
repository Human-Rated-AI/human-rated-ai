// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  FirestoreManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/27/25.
//

#if os(Android)
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif
import SwiftUI

public class FirestoreManager: ObservableObject {
    public static let shared = FirestoreManager()
    private init() {}
}

// MARK: - AI Settings Public Methods
extension FirestoreManager {
    // MARK: - AI Settings
    /// Delete an AI setting by its document ID
    /// - Parameters:
    ///   - documentID: The Firestore document ID of the AI setting
    ///   - userID: The user ID who owns the AI setting
    public func deleteAISetting(documentID: String, userID: String) async throws {
        let docRef = FirestoreQueries.getAISetting(documentID: documentID)
        let document = try await docRef.getDocument()
        guard document.exists,
              let data = document.data(),
              let docUserID = data["userID"] as? String,
              docUserID == userID else {
            throw NSError(domain: "FirestoreError",
                          code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Permission denied or AI Setting not found"])
        }
        try await docRef.delete()
    }
    
    /// Get a specific AI setting by its document ID
    /// - Parameter documentID: The Firestore document ID
    /// - Returns: The AI setting if found, nil otherwise
    public func getAISetting(documentID: String) async throws -> AISetting? {
        let docRef = FirestoreQueries.getAISetting(documentID: documentID)
        let document = try await docRef.getDocument()
        guard document.exists else { return nil }
        return aiSettingFrom(document: document, withID: documentID)
    }
    
    /// Get all public AI settings (for browsing in the AI tab)
    /// - Returns: Array of AISetting objects
    public func getAllPublicAISettings() async throws -> AISettings {
        let query = FirestoreQueries.getAllPublicAISettings()
        let snapshot = try await query.getDocuments()
        return aiSettingsFrom(snapshot)
    }
    
    /// Get all AI settings created by a specific user
    /// - Parameter userID: The ID of the user
    /// - Returns: Array of AISetting objects
    public func getUserAISettings(userID: String) async throws -> AISettings {
        let query = FirestoreQueries.getUserAISettings(userID: userID)
        let snapshot = try await query.getDocuments()
        return aiSettingsFrom(snapshot)
    }
    
    /// Check if an image URL is used by other bots
    /// - Parameters:
    ///   - imageURL: The image URL to check
    ///   - excludingBotID: Optional bot ID to exclude from the check
    /// - Returns: True if the image is used by other bots, false otherwise
    public func isImageUsedByOtherBots(imageURL: URL, excludingBotID: String? = nil) async throws -> Bool {
        // Build query for bots that use this image URL
        let query = FirestoreQueries.isImageUsedByOtherBots(imageURL: imageURL, excludingBotID: excludingBotID)
        let snapshot = try await query.getDocuments()
        // If there's at least one document, the image is used by other bots
        return snapshot.documents.isNotEmpty
    }
    
    /// Save a new AI setting to Firestore
    /// - Parameters:
    ///   - aiSetting: The AI setting to save
    ///   - userID: The ID of the user creating the AI setting
    /// - Returns: The document ID of the saved AI setting
    public func saveAISetting(_ aiSetting: AISetting, userID: String) async throws -> String {
        let data = prepareAISettingData(aiSetting, userID: userID, isUpdating: false)
        // Save to Firestore
        let docRef = try await FirestoreQueries.addAISetting(data: data)
        return docRef.documentID
    }
    
    /// Update an existing AI setting in Firestore
    /// - Parameters:
    ///   - aiSetting: The AI setting to update
    ///   - userID: The ID of the user updating the AI setting
    /// - Returns: Success flag
    public func updateAISetting(_ aiSetting: AISetting, userID: String) async throws -> Bool {
        // Verify the document exists and belongs to the user
        let docRef = FirestoreQueries.getAISetting(documentID: aiSetting.id)
        let document = try await docRef.getDocument()
        guard document.exists,
              let data = document.data(),
              let docUserID = data["userID"] as? String,
              docUserID == userID else {
            throw NSError(domain: "FirestoreError",
                          code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Permission denied or AI Setting not found"])
        }
        // Get the previous image URL before updating
        var previousImageURL: URL? = nil
        if let imageURLString = data[AISetting.CodingKeys.imageURL.rawValue] as? String {
            previousImageURL = URL(string: imageURLString)
        }
        // Update the document
        let updateData = prepareAISettingData(aiSetting, userID: userID, isUpdating: true)
        try await docRef.updateData(updateData)
        // If the image URL has changed and the previous URL was a user upload,
        // check if it's still used by other bots and delete if not
        if let prevURL = previousImageURL,
           aiSetting.imageURL?.absoluteString != prevURL.absoluteString,
           StorageManager.shared.isUserUploadedImage(prevURL, userID: userID) {
            let isUsedByOthers = try await isImageUsedByOtherBots(imageURL: prevURL, excludingBotID: aiSetting.id)
            if isUsedByOthers.isFalse {
                // The image is no longer used, so delete it
                try await StorageManager.shared.deleteFileFromURL(prevURL)
            }
        }
        return true
    }
    
    // MARK: - User Favorites
    /// Add an AI setting to user's favorites
    /// - Parameters:
    ///   - documentID: The Firestore document ID of the AI setting
    ///   - userID: The user ID
    public func addToFavorites(documentID: String, userID: String) async throws {
        let data: [String: Any] = [
            "addedAt": FieldValue.serverTimestamp(),
            "settingID": documentID,
        ]
        try await FirestoreQueries.userFavorite(userID: userID, documentID: documentID).setData(data)
    }
    
    /// Get user's favorite AI settings
    /// - Parameter userID: The user ID
    /// - Returns: Array of AI settings that the user has favorited
    public func getUserFavorites(userID: String) async throws -> AISettings {
        // First get the IDs of favorited settings
        let favoritesSnapshot = try await FirestoreQueries.userFavoritesCollection(userID: userID).getDocuments()
        let favoriteIDs = favoritesSnapshot.documents.compactMap { document in
            document.data()["settingID"] as? String
        }
        // If there are no favorites, return empty array
        if favoriteIDs.isEmpty { return [] }
        // Fetch the actual AI settings using the IDs
        // Firestore doesn't support direct "IN" queries for document IDs, so we need to do multiple gets
        var favoriteSettings: AISettings = []
        // Batch the requests in groups to avoid excessive queries
        let batchSize = 10
        for i in stride(from: 0, to: favoriteIDs.count, by: batchSize) {
            let endIndex = min(i + batchSize, favoriteIDs.count)
            let batch = favoriteIDs[i..<endIndex]
            var fetchTasks: [Task<AISetting?, Error>] = []
            for id in batch {
                let task = Task<AISetting?, Error> {
                    do {
                        let docRef = FirestoreQueries.getAISetting(documentID: id)
                        let doc = try await docRef.getDocument()
                        guard doc.exists else { return nil }
                        // Parse the document data into an AISetting
                        return aiSettingFrom(document: doc, withID: id)
                    } catch {
                        // If we can't access the bot (permission error or deleted), skip it
                        debug("WARN", FirestoreManager.self,
                              "Skipping inaccessible favorite bot \(id): \(error.localizedDescription)")
                        return nil
                    }
                }
                fetchTasks.append(task)
            }
            // Wait for all fetches in this batch to complete
            for task in fetchTasks {
                do {
                    if let setting = try await task.value {
                        favoriteSettings.append(setting)
                    }
                } catch {
                    // Task failed, but we already handled it inside the task
                    continue
                }
            }
        }
        return favoriteSettings
    }
    
    /// Get raw user favorite IDs (for cleanup purposes)
    /// - Parameter userID: The user ID
    /// - Returns: Array of favorite bot IDs (without trying to fetch the actual bots)
    public func getRawUserFavoriteIDs(userID: String) async throws -> [String] {
        let favoritesSnapshot = try await FirestoreQueries.userFavoritesCollection(userID: userID).getDocuments()
        return favoritesSnapshot.documents.compactMap { document in
            document.data()["settingID"] as? String
        }
    }
    
    /// Remove an AI setting from user's favorites
    /// - Parameters:
    ///   - documentID: The Firestore document ID of the AI setting
    ///   - userID: The user ID
    public func removeFromFavorites(documentID: String, userID: String) async throws {
        try await FirestoreQueries.userFavorite(userID: userID, documentID: documentID).delete()
    }
    
    // MARK: - Ratings
    /// Get all ratings (for showing in the UI)
    /// - Returns: Dictionary mapping AI setting IDs to their average ratings
    public func getAllRatings() async throws -> [String: Double] {
        let snapshot = try await FirestoreQueries.getAllAISettings()
        var ratingsDict: [String: Double] = [:]
        for document in snapshot.documents {
            let docID = document.documentID
            if let averageRating = try? await getAverageRating(for: docID) {
                ratingsDict[docID] = averageRating
            }
        }
        return ratingsDict
    }
    
    /// Get the average rating for an AI setting
    /// - Parameter documentID: The Firestore document ID of the AI setting
    /// - Returns: The average rating or nil if no ratings exist
    public func getAverageRating(for documentID: String) async throws -> Double? {
        let query = FirestoreQueries.getRatingsForAISetting(documentID: documentID)
        let snapshot = try await query.getDocuments()
        if snapshot.documents.isEmpty { return nil }
        let total = snapshot.documents.reduce(Double(0)) { sum, document in
            sum + (document.data()["rating"] as? Double ?? Double(0))
        }
        return total / Double(snapshot.documents.count)
    }
    
    /// Rate an AI setting
    /// - Parameters:
    ///   - documentID: The Firestore document ID of the AI setting
    ///   - rating: Rating value (1-5)
    ///   - userID: The user ID providing the rating
    public func rateAISetting(documentID: String, rating: Double, userID: String) async throws {
        guard 1 <= rating && rating <= 5 else {
            throw NSError(domain: "RatingError",
                          code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Rating must be between 1 and 5"])
        }
        // Verify the setting exists
        let docRef = FirestoreQueries.getAISetting(documentID: documentID)
        let document = try await docRef.getDocument()
        guard document.exists else {
            throw NSError(domain: "FirestoreError",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "AI Setting not found"])
        }
        let data: [String: Any] = [
            "ratedAt": FieldValue.serverTimestamp(),
            "rating": rating,
            "settingID": documentID,
            "userID": userID
        ]
        // Add to ratings collection
        try await FirestoreQueries.getUserRatingForAISetting(documentID: documentID, userID: userID).setData(data)
        // Update average rating for the AI setting
        await updateAverageRating(for: documentID)
    }
}

// MARK: - AI Settings Data Helpers
private extension FirestoreManager {
    /// Create an AISetting from a DocumentSnapshot
    /// - Parameters:
    ///   - document: The document snapshot
    ///   - id: The document ID
    /// - Returns: An AISetting object or nil if required fields are missing
    func aiSettingFrom(document: DocumentSnapshot, withID id: String) -> AISetting? {
        let data = document.data() ?? [:]
        // Extract required fields
        guard let name = data[AISetting.CodingKeys.name.rawValue] as? String else { return nil }
        // Create AISetting object with the document ID
        var aiSetting = AISetting(id: id, name: name)
        // Set optional fields
        aiSetting.desc = data[AISetting.CodingKeys.desc.rawValue] as? String
        if let imageURLString = data[AISetting.CodingKeys.imageURL.rawValue] as? String {
            aiSetting.imageURL = URL(string: imageURLString)
        }
        aiSetting.caption = data[AISetting.CodingKeys.caption.rawValue] as? String
        if let isOpenSource = data[AISetting.CodingKeys.isOpenSource.rawValue] as? Bool {
            aiSetting.isOpenSource = isOpenSource
        }
        if let isPublic = data[AISetting.CodingKeys.isPublic.rawValue] as? Bool {
            aiSetting.isPublic = isPublic
        }
        aiSetting.prefix = data[AISetting.CodingKeys.prefix.rawValue] as? String
        aiSetting.suffix = data[AISetting.CodingKeys.suffix.rawValue] as? String
        aiSetting.welcome = data[AISetting.CodingKeys.welcome.rawValue] as? String
        return aiSetting
    }
    
    /// Create AISettings from given query snapshot
    /// - Parameter snapshot: query snapshot from Firebase
    /// - Returns: AISettings or empty array
    func aiSettingsFrom(_ snapshot: QuerySnapshot) -> AISettings {
        return snapshot.documents.compactMap { document in
            aiSettingFrom(document: document, withID: document.documentID)
        }
    }
    
    /// Prepare AI setting data for Firestore
    /// - Parameters:
    ///   - aiSetting: The AI setting to prepare data for
    ///   - userID: The ID of the user
    ///   - isUpdate: Whether this is for an update (true) or new document (false)
    /// - Returns: Dictionary with data for Firestore
    func prepareAISettingData(_ aiSetting: AISetting, userID: String, isUpdating: Bool) -> [String: Any] {
        let aiSetting = aiSetting.trimmed
        var data: [String: Any] = [
            AISetting.CodingKeys.name.rawValue: aiSetting.name,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        // Add creation-specific fields
        if isUpdating.isFalse {
            data["createdAt"] = FieldValue.serverTimestamp()
            data["userID"] = userID
        }
        // Handle optional fields
        let optionalFields: [(key: AISetting.CodingKeys, value: Any?)] = [
            (.desc, aiSetting.desc),
            (.caption, aiSetting.caption),
            (.isOpenSource, aiSetting.isOpenSource ? true : nil),
            (.isPublic, aiSetting.isPublic ? true : nil),
            (.prefix, aiSetting.prefix),
            (.suffix, aiSetting.suffix),
            (.welcome, aiSetting.welcome)
        ]
        for (key, value) in optionalFields {
            if let value {
                data[key.rawValue] = value
            } else if isUpdating {
                // Only delete fields if this is an update operation
                data[key.rawValue] = FieldValue.delete()
            }
        }
        // Handle image URL separately since it's a URL, not a String
        if let imageURL = aiSetting.imageURL?.absoluteString {
            data[AISetting.CodingKeys.imageURL.rawValue] = imageURL
        } else if isUpdating {
            data[AISetting.CodingKeys.imageURL.rawValue] = FieldValue.delete()
        }
        return data
    }
    
    /// Update the average rating for an AI setting
    /// - Parameter documentID: The Firestore document ID of the AI setting
    func updateAverageRating(for documentID: String) async {
        do {
            if let averageRating = try await getAverageRating(for: documentID) {
                let docRef = FirestoreQueries.getAISetting(documentID: documentID)
                try await docRef.updateData(["averageRating": averageRating])
            }
        } catch {
            debug("FAIL", Self.self, "Failed to update average rating: \(error.localizedDescription)")
        }
    }
}
