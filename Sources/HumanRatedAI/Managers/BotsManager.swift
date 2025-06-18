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
                    
                    // Get user favorites
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
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
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
