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
    @State private var publicBots: AISettings = []
    @State private var ratings: [String: Double] = [:]
    @State private var userBots: AISettings = []
    @State private var userFavorites: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                if publicBots.isEmpty && userBots.isEmpty && isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if errorMessage.notEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Error Loading AI bots")
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            loadAIBots()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if publicBots.isEmpty && userBots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No AI bots found")
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Check back later or create your own!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if userBots.isNotEmpty {
                            Section(header: Text("My Bots").font(.headline)) {
                                AIBotListSection(
                                    bots: userBots,
                                    ratings: ratings,
                                    onAddToFavorite: { bot in
                                        addToFavorites(bot)
                                    },
                                    onRemoveFavorite: { bot in
                                        removeFromFavorites(bot)
                                    },
                                    userFavorites: userFavorites
                                )
                            }
                        }
                        
                        if publicBots.isNotEmpty {
                            Section(header: Text("Public Bots").font(.headline)) {
                                AIBotListSection(
                                    bots: publicBots,
                                    ratings: ratings,
                                    onAddToFavorite: { bot in
                                        addToFavorites(bot)
                                    },
                                    onRemoveFavorite: { bot in
                                        removeFromFavorites(bot)
                                    },
                                    userFavorites: userFavorites
                                )
                            }
                        }
                    }
#if !os(Android)
                    .listStyle(InsetGroupedListStyle())
#endif
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
            }
            .navigationTitle("AI Bot List")
            .onAppear {
                loadAIBots()
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
    
    func loadAIBots() {
        if isLoading { return }
        isLoading = true
        errorMessage = ""
        Task {
            do {
                // Get all public AI bots settings
                let allPublicSettings = try await FirestoreManager.shared.getAllPublicAISettings()
                // Get ratings
                let allRatings = try? await FirestoreManager.shared.getAllRatings()
                var userBotsResult: AISettings = []
                // Get user bots and favorites if logged in
                if let user = authManager.user {
                    // Get user's own bots
                    userBotsResult = try await FirestoreManager.shared.getUserAISettings(userID: user.uid)
                    // Get user favorites
                    let favorites = try await FirestoreManager.shared.getUserFavorites(userID: user.uid)
                    await MainActor.run {
                        userFavorites = favorites.map { $0.id }
                    }
                }
                await MainActor.run {
                    publicBots = allPublicSettings.filter { bot in
                        // Don't show bots in public section that are already in user's section
                        userBotsResult.contains(where: { $0.id == bot.id }).isFalse
                    }
                    userBots = userBotsResult
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
}

// Helper component to display the bot list in each section
private struct AIBotListSection: View {
    let bots: AISettings
    let ratings: [String: Double]
    var onAddToFavorite: ((AISetting) -> Void)?
    var onRemoveFavorite: ((AISetting) -> Void)?
    var userFavorites: [String] = []
    
    var body: some View {
        ForEach(bots, id: \.id) { bot in
            NavigationLink(destination: Text("Chat with \(bot.name)")) {
                AIBotRow(
                    bot: bot,
                    rating: ratings[bot.id] ?? 0.0,
                    isFavorite: userFavorites.contains(bot.id),
                    onToggleFavorite: {
                        if userFavorites.contains(bot.id) {
                            onRemoveFavorite?(bot)
                        } else {
                            onAddToFavorite?(bot)
                        }
                    }
                )
            }
        }
    }
}

// Bot row component
private struct AIBotRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let bot: AISetting
    let rating: Double
    let isFavorite: Bool
    var onToggleFavorite: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 15) {
            // Image or placeholder
            if let imageURL = bot.imageURL {
                CachedImage(url: imageURL) { imageData in
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                } placeholder: {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // Bot details
            VStack(alignment: .leading, spacing: 5) {
                // Name and description
                Text(bot.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(bot.desc ?? "No description available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                // Public and open source tags
                HStack(spacing: 4) {
                    if bot.isPublic {
                        AIBotTag(color: .blue, text: "Public")
                    } else {
                        AIBotTag(color: .red, text: "Private")
                    }
                    if bot.isOpenSource {
                        AIBotTag(color: .green, text: "Open")
                    }
                }
                // Rating
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        let fullStars = Int(rating)
                        let fraction = rating - Double(fullStars)
                        if star <= fullStars {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        } else if Double(star - 1) < rating && rating < Double(star) && 0.49999 < fraction {
#if os(Android)
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
#else
                            Image(systemName: "star.leadinghalf.fill")
                                .foregroundColor(.yellow)
#endif
                        } else {
#if os(Android)
                            Image(systemName: "star.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
#else
                            Image(systemName: "star")
                                .foregroundColor(.yellow)
#endif
                        }
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Favorite toggle button
            if let toggleAction = onToggleFavorite {
                Button(action: toggleAction) {
#if os(Android)
                    Image(systemName: "star.fill")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(isFavorite ? .body : .caption)
#else
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
#endif
                }
            }
        }
        .padding(.vertical, 5)
    }
}

private struct AIBotTag: View {
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
