// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AITabView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/15/25.
//  Created by Grok 3 on 3/13/25.
//

import SwiftUI

struct AITabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authManager: AuthManager
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var navigationPath = NavigationPath()
    @State private var publicBots: AISettings = []
    @State private var ratings: [String: Double] = [:]
    @State private var showAuthSheet = false
    @State private var userBots: AISettings = []
    @State private var userFavorites: [String] = []
    let showFavoritesOnly: Bool
    
    private var filteredPublicBots: AISettings {
        showFavoritesOnly ? publicBots.filter { userFavorites.contains($0.id) } : publicBots
    }
    
    private var filteredUserBots: AISettings {
        showFavoritesOnly ? userBots.filter { userFavorites.contains($0.id) } : userBots
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack(path: $navigationPath) {
                ZStack {
                    if filteredPublicBots.isEmpty && filteredUserBots.isEmpty && isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if errorMessage.notEmpty {
                        ErrorView("Error Loading AI bots", message: errorMessage, tryAgainAction: loadAIBots)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredPublicBots.isEmpty && filteredUserBots.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text(showFavoritesOnly ? "No favorites yet." : "No AI bots found")
                                .font(.title2)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text(showFavoritesOnly ? "Add some from the AI tab!" : "Check back later or create your own!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            if filteredUserBots.isNotEmpty {
                                Section(header: Text("My Bots").font(.headline)) {
                                    AIBotListSection(showAuthSheet: $showAuthSheet,
                                                     bots: filteredUserBots,
                                                     geometry: geometry,
                                                     isUserBotSection: true,
                                                     navigateToChat: { bot, isUserBot in
                                        navigationPath.append(ChatDestination(bot: bot, isUserBot: isUserBot))
                                    },
                                                     onAddToFavorite: { addToFavorites($0) },
                                                     onRemoveFavorite: { removeFromFavorites($0) },
                                                     ratings: ratings,
                                                     userFavorites: userFavorites)
                                }
                            }
                            
                            if filteredPublicBots.isNotEmpty {
                                Section(header: Text("Public Bots").font(.headline)) {
                                    AIBotListSection(showAuthSheet: $showAuthSheet,
                                                     bots: filteredPublicBots,
                                                     geometry: geometry,
                                                     isUserBotSection: false,
                                                     navigateToChat: { bot, isUserBot in
                                        navigationPath.append(ChatDestination(bot: bot, isUserBot: isUserBot))
                                    },
                                                     onAddToFavorite: { addToFavorites($0) },
                                                     onRemoveFavorite: { removeFromFavorites($0) },
                                                     ratings: ratings,
                                                     userFavorites: userFavorites)
                                }
                            }
                        }
#if os(Android)
                        .listStyle(.plain)
                        .padding()
#else
                        .listStyle(.insetGrouped)
#endif
                    }
                }
                .navigationDestination(for: ChatDestination.self) { destination in
                    ChatView(bot: destination.bot, isUserBot: destination.isUserBot)
                }
                .navigationTitle(showFavoritesOnly ? "Favorite Bots" : "AI Bot List")
                .onAppear {
                    loadAIBots()
                }
                .sheet(isPresented: $showAuthSheet) {
                    AuthView(showAuthSheet: $showAuthSheet)
                }
            }
        }
    }
}

private extension AITabView {
    func addToFavorites(_ bot: AISetting) {
        guard let user = authManager.user else { return }
        Task {
            do {
                try await FirestoreManager.shared.addToFavorites(documentID: bot.id, userID: user.uid)
                await MainActor.run {
                    userFavorites.append(bot.id)
                }
            } catch {
                debug("FAIL", AITabView.self, "Error adding to favorites: \(error.localizedDescription)")
            }
        }
    }
    
    func loadAIBots() {
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
    
    func removeFromFavorites(_ bot: AISetting) {
        guard let user = authManager.user else { return }
        Task {
            do {
                try await FirestoreManager.shared.removeFromFavorites(documentID: bot.id, userID: user.uid)
                await MainActor.run {
                    userFavorites.removeAll { $0 == bot.id }
                }
            } catch {
                debug("FAIL", AITabView.self, "Error removing from favorites: \(error.localizedDescription)")
            }
        }
    }
}

// Helper component to display the bot list in each section
private struct AIBotListSection: View {
    @Binding var showAuthSheet: Bool
    let bots: AISettings
    let geometry: GeometryProxy
    let isUserBotSection: Bool
    let navigateToChat: ((AISetting, Bool) -> Void)
    let onAddToFavorite: ((AISetting) -> Void)?
    let onRemoveFavorite: ((AISetting) -> Void)?
    let ratings: [String: Double]
    let userFavorites: [String]
    
    var body: some View {
        ForEach(bots.sorted(), id: \.id) { bot in
            VStack(alignment: .leading, spacing: 8) {
                // Top row with image and text
                Button(action: {
                    navigateToChat(bot, isUserBotSection)
                }) {
                    AIBotListItem(bot: bot, geometry: geometry, ratings: ratings)
                }
                .buttonStyle(.plain)
                
                // Bottom row with tags, rating, and favorite button
                AIBotListItemBottomRow(showAuthSheet: $showAuthSheet,
                                       bot: bot,
                                       onAddToFavorite: onAddToFavorite,
                                       onRemoveFavorite: onRemoveFavorite,
                                       ratings: ratings,
                                       userFavorites: userFavorites)
            }
            .padding(.vertical, 8)
        }
    }
}

private struct AIBotListItem: View {
    let bot: AISetting
    let geometry: GeometryProxy
    let ratings: [String: Double]
    
    var body: some View {
        // Top row with image and text
        HStack(spacing: 15) {
            // Bot image
            AvatarView(imageURL: bot.imageURL, width: 50, height: 50)
            
            // Bot details
            VStack(alignment: .leading, spacing: 5) {
                // Name and description
                Text(bot.name)
                    .font(.headline)
                Text(bot.desc ?? "No description available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: geometry.size.width - 134, alignment: .leading)
            
            // Push content to the left and add disclosure indicator
            Spacer()
            
            // Disclosure indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

private struct AIBotListItemBottomRow: View {
    @Binding var showAuthSheet: Bool
    let bot: AISetting
    let onAddToFavorite: ((AISetting) -> Void)?
    let onRemoveFavorite: ((AISetting) -> Void)?
    let ratings: [String: Double]
    let userFavorites: [String]
    
    var body: some View {
        // Bottom row with tags and rating
        HStack(spacing: 4) {
            // Tags
            if bot.isPublic {
                AIBotTag(color: .blue, text: "Public")
            } else {
                AIBotTag(color: .red, text: "Private")
            }
            if bot.isOpenSource {
                AIBotTag(color: .green, text: "Open")
            }
            
            Spacer()
            
            // Rating stars
            let rating = ratings[bot.id] ?? 0.0
            ForEach(1...5, id: \.self) { star in
                let fullStars = Int(rating)
                let fraction = rating - Double(fullStars)
                if star <= fullStars {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                } else if Double(star - 1) < rating && rating < Double(star) && 0.49999 < fraction {
#if os(Android)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
#else
                    Image(systemName: "star.leadinghalf.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
#endif
                } else {
#if os(Android)
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray)
                        .font(.caption2)
#else
                    Image(systemName: "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
#endif
                }
            }
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Favorite button
            AIBotListItemFavoriteButton(showAuthSheet: $showAuthSheet,
                                        bot: bot,
                                        onAddToFavorite: onAddToFavorite,
                                        onRemoveFavorite: onRemoveFavorite,
                                        userFavorites: userFavorites)
        }
    }
}

private struct AIBotListItemFavoriteButton: View {
    @Binding var showAuthSheet: Bool
    @EnvironmentObject var authManager: AuthManager
    let bot: AISetting
    let onAddToFavorite: ((AISetting) -> Void)?
    let onRemoveFavorite: ((AISetting) -> Void)?
    let userFavorites: [String]
    
    var body: some View {
        // Favorite button - outside NavigationLink
        Button {
            // Disable navigation when favorite button is tapped
            if authManager.isAuthenticated {
                if userFavorites.contains(bot.id) {
                    onRemoveFavorite?(bot)
                } else {
                    onAddToFavorite?(bot)
                }
            } else {
                showAuthSheet = true
            }
        } label: {
#if os(Android)
            Image(systemName: "star.fill")
                .foregroundColor(userFavorites.contains(bot.id) ? .yellow : .gray)
                .font(userFavorites.contains(bot.id) ? .body : .caption)
                .frame(width: 44, height: 44)
#else
            Image(systemName: userFavorites.contains(bot.id) ? "star.fill" : "star")
                .foregroundColor(.yellow)
                .frame(width: 44, height: 44)
#endif
        }
    }
}

struct AIBotTag: View {
    let color: Color
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

private struct ChatDestination: Hashable {
    let bot: AISetting
    let isUserBot: Bool
}
