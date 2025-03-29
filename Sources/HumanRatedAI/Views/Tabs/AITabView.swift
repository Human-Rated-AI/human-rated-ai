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
    @State private var aiBots: AISettings = []
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var ratings: [String: Double] = [:]
    @State private var userFavorites: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                if aiBots.isEmpty && isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if errorMessage.isNotEmpty {
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
                } else if aiBots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No public AI bots found")
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Check back later or create your own!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AIBotListView(bots: aiBots, ratings: ratings, onAddToFavorite: { bot in
                        addToFavorites(bot)
                    })
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
        
    }
    
    func loadAIBots() {
        if isLoading { return }
        isLoading = true
        errorMessage = ""
        Task {
            do {
                // Get all public AI bots settings
                let allSettings = try await FirestoreManager.shared.getAllPublicAISettings()
                // Get ratings
                let allRatings = try? await FirestoreManager.shared.getAllRatings()
                // Get user favorites if logged in
                if let user = authManager.user {
                    let favorites = try await FirestoreManager.shared.getUserFavorites(userID: user.uid)
                    await MainActor.run {
                        userFavorites = favorites.map { $0.id }
                    }
                }
                await MainActor.run {
                    aiBots = allSettings
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
