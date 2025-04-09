// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  FirestoreQueries.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/9/25.
//

#if os(Android)
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif
import Foundation

struct FirestoreQueries {
    // MARK: - AI Settings Queries
    /// Get a query for a specific AI setting by document ID
    static func addAISetting(data: [String: Any]) async throws -> DocumentReference {
        try await Firestore.firestore().aiSettings.addDocument(data: data)
    }
    
    static func getAllAISettings() async throws -> QuerySnapshot {
        try await Firestore.firestore().aiSettings.getDocuments()
    }
    
    /// Get a query for all public AI settings
    static func getAllPublicAISettings() -> Query {
        Firestore.firestore().aiSettings
            .whereField(AISetting.CodingKeys.isPublic.rawValue, isEqualTo: true)
    }
    
    /// Get a query for a specific AI setting by document ID
    static func getAISetting(documentID: String) -> DocumentReference {
        Firestore.firestore().aiSettings.document(documentID)
    }
    
    /// Get a query for all AI settings created by a specific user
    static func getUserAISettings(userID: String) -> Query {
        Firestore.firestore().aiSettings.whereField("userID", isEqualTo: userID)
    }
    
    /// Get a query to check if an image URL is used by other bots
    static func isImageUsedByOtherBots(imageURL: URL, excludingBotID: String? = nil) -> Query {
        let urlString = imageURL.absoluteString
        var query = Firestore.firestore().aiSettings
            .whereField(AISetting.CodingKeys.imageURL.rawValue, isEqualTo: urlString)
            .limit(to: 1)
        
        if let excludingBotID {
            let documentIDField = FieldPath.documentID()
            query = query.whereField(documentIDField, isNotEqualTo: excludingBotID)
        }
        
        return query
    }
    
    // MARK: - User and Favorites Queries
    static func getUser(userID: String) -> DocumentReference {
        Firestore.firestore().users.document(userID)
    }
    
    /// Get a reference to a user's favorites collection
    static func userFavoritesCollection(userID: String) -> CollectionReference {
        getUser(userID: userID).collection("favorites")
    }
    
    /// Get a query for a specific favorite in a user's favorites
    static func userFavorite(userID: String, documentID: String) -> DocumentReference {
        userFavoritesCollection(userID: userID).document(documentID)
    }
    
    // MARK: - Ratings Queries
    /// Get a query for ratings of a specific AI setting
    static func getRatingsForAISetting(documentID: String) -> Query {
        Firestore.firestore().ratings.whereField("settingID", isEqualTo: documentID)
    }
    
    /// Get a document reference for a user's rating of an AI setting
    static func getUserRatingForAISetting(documentID: String, userID: String) -> DocumentReference {
        Firestore.firestore().ratings.document("\(documentID)_\(userID)")
    }
}

// MARK: - Private Helpers
private extension Firestore {
    var aiSettings: CollectionReference { collection("aiSettings") }
    var ratings: CollectionReference { collection("ratings") }
    var users: CollectionReference { collection("users") }
}
