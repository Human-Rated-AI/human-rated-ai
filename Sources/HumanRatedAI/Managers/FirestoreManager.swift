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
    
    private let db: Firestore
    
    private init() {
        self.db = Firestore.firestore()
    }
    
    // MARK: - AI Settings
    /// Save an AI setting to Firestore
    /// - Parameters:
    ///   - aiSetting: The AI setting to save
    ///   - userID: The ID of the user creating the AI setting
    /// - Returns: The document ID of the saved AI setting
    public func saveAISetting(_ aiSetting: AISetting, userID: String) async throws -> String {
        var data: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            AISetting.CodingKeys.isPublic.rawValue: aiSetting.isPublic,
            AISetting.CodingKeys.name.rawValue: aiSetting.name,
            "updatedAt": FieldValue.serverTimestamp(),
            "userID": userID
        ]
        
        // Add optional fields if they exist
        if let desc = aiSetting.desc {
            data[AISetting.CodingKeys.desc.rawValue] = desc
        }
        
        if let imageURL = aiSetting.imageURL?.absoluteString {
            data[AISetting.CodingKeys.imageURL.rawValue] = imageURL
        }
        
        if let caption = aiSetting.caption {
            data[AISetting.CodingKeys.caption.rawValue] = caption
        }
        
        if let prefix = aiSetting.prefix {
            data[AISetting.CodingKeys.prefix.rawValue] = prefix
        }
        
        if let suffix = aiSetting.suffix {
            data[AISetting.CodingKeys.suffix.rawValue] = suffix
        }
        
        if let welcome = aiSetting.welcome {
            data[AISetting.CodingKeys.welcome.rawValue] = welcome
        }
        
        // Save to Firestore
        let docRef = try await db.aiSettings.addDocument(data: data)
        return docRef.documentID
    }
    
    /// Get all AI settings created by a specific user
    /// - Parameter userID: The ID of the user
    /// - Returns: Array of AISetting objects
    public func getUserAISettings(userID: String) async throws -> AISettings {
        let query = db.aiSettings.whereField("userID", isEqualTo: userID)
        let snapshot = try await query.getDocuments()
        return aiSettingsFrom(snapshot)
    }
    
    /// Get all public AI settings (for browsing in the AI tab)
    /// - Returns: Array of AISetting objects
    public func getAllPublicAISettings() async throws -> AISettings {
        let query = db.aiSettings.whereField(AISetting.CodingKeys.isPublic.rawValue, isEqualTo: true)
        let snapshot = try await query.getDocuments()
        return aiSettingsFrom(snapshot)
    }
    
    /// Delete an AI setting
    /// - Parameters:
    ///   - name: The name of the AI setting to delete
    ///   - userID: The user ID who owns the AI setting
    public func deleteAISetting(name: String, userID: String) async throws {
        let query = db.aiSettings
            .whereField(AISetting.CodingKeys.name.rawValue, isEqualTo: name)
            .whereField("userID", isEqualTo: userID)
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "FirestoreError",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "AI Setting not found"])
        }
        try await document.reference.delete()
    }
    
    // MARK: - User Favorites
    /// Add an AI setting to user's favorites
    /// - Parameters:
    ///   - settingName: The name of the AI setting
    ///   - userID: The user ID
    public func addToFavorites(settingName: String, userID: String) async throws {
        let data: [String: Any] = [
            "addedAt": FieldValue.serverTimestamp(),
            "settingName": settingName,
        ]
        try await db.users.document(userID).collection("favorites").document(settingName).setData(data)
    }
    
    /// Remove an AI setting from user's favorites
    /// - Parameters:
    ///   - settingName: The name of the AI setting
    ///   - userID: The user ID
    public func removeFromFavorites(settingName: String, userID: String) async throws {
        try await db.users.document(userID).collection("favorites").document(settingName).delete()
    }
    
    /// Get user's favorite AI settings
    /// - Parameter userID: The user ID
    /// - Returns: Array of favorite AI setting names
    public func getUserFavorites(userID: String) async throws -> [String] {
        let snapshot = try await db.users.document(userID).collection("favorites").getDocuments()
        return snapshot.documents.compactMap { document in
            document.data()["settingName"] as? String
        }
    }
    
    // MARK: - Ratings
    /// Rate an AI setting
    /// - Parameters:
    ///   - settingName: The name of the AI setting
    ///   - rating: Rating value (1-5)
    ///   - userID: The user ID providing the rating
    public func rateAISetting(settingName: String, rating: Double, userID: String) async throws {
        guard 1 <= rating && rating <= 5 else {
            throw NSError(domain: "RatingError",
                          code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Rating must be between 1 and 5"])
        }
        let data: [String: Any] = [
            "ratedAt": FieldValue.serverTimestamp(),
            "rating": rating,
            "userID": userID
        ]
        // Add to user's ratings
        try await db.ratings.document("\(settingName)_\(userID)").setData(data)
        // Update average rating for the AI setting
        await updateAverageRating(for: settingName)
    }
    
    /// Get the average rating for an AI setting
    /// - Parameter settingName: The name of the AI setting
    /// - Returns: The average rating or nil if no ratings exist
    public func getAverageRating(for settingName: String) async throws -> Double? {
        let query = db.ratings.whereField("settingName", isEqualTo: settingName)
        let snapshot = try await query.getDocuments()
        if snapshot.documents.isEmpty { return nil }
        let total = snapshot.documents.reduce(Double(0)) { sum, document in
            sum + (document.data()["rating"] as? Double ?? Double(0))
        }
        return total / Double(snapshot.documents.count)
    }
    
    /// Get all ratings (for showing in the UI)
    /// - Returns: Dictionary mapping AI setting names to their average ratings
    public func getAllRatings() async throws -> [String: Double] {
        let snapshot = try await db.aiSettings.getDocuments()
        var ratingsDict: [String: Double] = [:]
        for document in snapshot.documents {
            if let name = document.data()[AISetting.CodingKeys.name.rawValue] as? String,
               let averageRating = try? await getAverageRating(for: name) {
                ratingsDict[name] = averageRating
            }
        }
        return ratingsDict
    }
}

// MARK: - Private Helpers
extension Firestore {
    fileprivate var aiSettings: CollectionReference { collection("aiSettings") }
    fileprivate var ratings: CollectionReference { collection("ratings") }
    var users: CollectionReference { collection("users") }
}

private extension FirestoreManager {
    /// Create AISettings from given query snapshot
    /// - Parameter snapshot: query snapshot from Firebase
    /// - Returns: AISettings or empty array
    func aiSettingsFrom(_ snapshot: QuerySnapshot) -> AISettings {
        return snapshot.documents.compactMap { document in
            let data = document.data()
            // Extract required fields
            let isPublic = data[AISetting.CodingKeys.isPublic.rawValue] as? Bool
            guard let name = data[AISetting.CodingKeys.name.rawValue] as? String else { return nil }
            // Create AISetting object
            var aiSetting = AISetting(isPublic: isPublic ?? false, name: name)
            // Set optional fields
            aiSetting.desc = data[AISetting.CodingKeys.desc.rawValue] as? String
            if let imageURLString = data[AISetting.CodingKeys.imageURL.rawValue] as? String {
                aiSetting.imageURL = URL(string: imageURLString)
            }
            aiSetting.caption = data[AISetting.CodingKeys.caption.rawValue] as? String
            aiSetting.prefix = data[AISetting.CodingKeys.prefix.rawValue] as? String
            aiSetting.suffix = data[AISetting.CodingKeys.suffix.rawValue] as? String
            aiSetting.welcome = data[AISetting.CodingKeys.welcome.rawValue] as? String
            return aiSetting
        }
    }
    
    /// Update the average rating for an AI setting
    /// - Parameter settingName: The name of the AI setting
    func updateAverageRating(for settingName: String) async {
        do {
            if let averageRating = try await getAverageRating(for: settingName) {
                // Find the AI setting document
                let query = db.aiSettings.whereField(AISetting.CodingKeys.name.rawValue, isEqualTo: settingName)
                let snapshot = try await query.getDocuments()
                
                if let document = snapshot.documents.first {
                    try await document.reference.updateData(["averageRating": averageRating])
                }
            }
        } catch {
            debug("FAIL", Self.self, "Failed to update average rating: \(error.localizedDescription)")
        }
    }
}
