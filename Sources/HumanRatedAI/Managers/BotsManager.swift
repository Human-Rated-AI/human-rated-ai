// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  BotsManager.swift
//  human-rated-ai
//
//  Created by Claude on 6/18/25.
//

import Foundation
import SwiftUI

/// Manages the collection of AI bots with reactive updates
class BotsManager: ObservableObject {
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var publicBots: AISettings = []
    @Published var userBots: AISettings = []
    @Published var userFavorites: [String] = []
    @Published var ratings: [String: Double] = [:]
    
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    /// Updates a specific bot in the appropriate collection
    func updateBot(_ updatedBot: AISetting) {
        // Update in userBots if it exists there
        if let userIndex = userBots.firstIndex(where: { $0.id == updatedBot.id }) {
            userBots[userIndex] = updatedBot
        }
        
        // Update in publicBots if it exists there
        if let publicIndex = publicBots.firstIndex(where: { $0.id == updatedBot.id }) {
            publicBots[publicIndex] = updatedBot
        }
    }
    
    /// Loads all bots from Firestore
    func loadBots() {
        if isLoading { return }
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                var aiSettings: AISettings = []
                
                // Get all public AI bots settings
                let allPublicSettings = try await FirestoreManager.shared.getAllPublicAISettings()
                
                // Get ratings
                let allRatings = try? await FirestoreManager.shared.getAllRatings()
                
                // Get user bots and favorites if logged in
                if let user = authManager.user {
                    // Get user's own bots
                    aiSettings = try await FirestoreManager.shared.getUserAISettings(userID: user.uid)
                    
                    // Create set of all accessible bot IDs (public + user's own bots)
                    let accessibleBotIDs = Set(allPublicSettings.map { $0.id } + aiSettings.map { $0.id })
                    
                    // Clean up orphaned favorites based on accessible bots
                    await cleanupOrphanedFavorites(userID: user.uid, accessibleBotIDs: accessibleBotIDs)
                    
                    // Get cleaned favorites
                    let favorites = try await FirestoreManager.shared.getUserFavorites(userID: user.uid)
                    await MainActor.run {
                        userFavorites = favorites.map { $0.id }
                    }
                }
                
                await MainActor.run {
                    publicBots = allPublicSettings.filter { bot in
                        // Don't show bots in public section that are already in user's section
                        aiSettings.contains(where: { $0.id == bot.id }).isFalse
                    }
                    userBots = aiSettings
                    ratings = allRatings ?? [:]
                    isLoading = false
                    print("✅ BotsManager: Successfully loaded \(publicBots.count) public bots, \(userBots.count) user bots, \(userFavorites.count) favorites")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("⚠️ BotsManager: Error loading bots: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Cleans up orphaned favorites (favorites that point to deleted bots)
    private func cleanupOrphanedFavorites(userID: String, accessibleBotIDs: Set<String>) async {
        do {
            // Get current favorites
            let currentFavorites = try await FirestoreManager.shared.getUserFavorites(userID: userID)
            
            // Find orphaned favorites (favorites that reference non-existent bots)
            let orphanedFavorites = currentFavorites.filter { favorite in
                !accessibleBotIDs.contains(favorite.id)
            }
            
            if orphanedFavorites.isEmpty {
                print("✅ BotsManager: No orphaned favorites found for user \(userID)")
                return
            }
            
            print("🧹 BotsManager: Found \(orphanedFavorites.count) orphaned favorite(s) for user \(userID)")
            
            // Remove each orphaned favorite
            for orphanedFavorite in orphanedFavorites {
                do {
                    try await FirestoreManager.shared.removeFromFavorites(documentID: orphanedFavorite.id, userID: userID)
                    print("✅ BotsManager: Removed orphaned favorite \(orphanedFavorite.id)")
                } catch {
                    print("⚠️ BotsManager: Failed to remove orphaned favorite \(orphanedFavorite.id): \(error.localizedDescription)")
                }
            }
            
            print("🎉 BotsManager: Finished cleaning up orphaned favorites for user \(userID)")
        } catch {
            print("⚠️ BotsManager: Error during favorite cleanup for user \(userID): \(error.localizedDescription)")
        }
    }
    
    /// Adds a bot to favorites
    func addToFavorites(_ bot: AISetting) {
        guard let user = authManager.user else { return }
        Task {
            do {
                try await FirestoreManager.shared.addToFavorites(documentID: bot.id, userID: user.uid)
                await MainActor.run {
                    userFavorites.append(bot.id)
                }
            } catch {
                debug("FAIL", BotsManager.self, "Error adding to favorites: \(error.localizedDescription)")
            }
        }
    }
    
    /// Removes a bot from favorites
    func removeFromFavorites(_ bot: AISetting) {
        guard let user = authManager.user else { return }
        Task {
            do {
                try await FirestoreManager.shared.removeFromFavorites(documentID: bot.id, userID: user.uid)
                await MainActor.run {
                    userFavorites.removeAll { $0 == bot.id }
                }
            } catch {
                debug("FAIL", BotsManager.self, "Error removing from favorites: \(error.localizedDescription)")
            }
        }
    }
}
