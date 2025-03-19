// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  FavsTabView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/15/25.
//  Created by Grok 3 on 3/13/25.
//

import SwiftUI

// Import our reusable component

struct FavsTabView: View {
    @State private var favoriteBots: [AISetting] = [
        AISetting(creatorID: 1,
                  desc: "Your personal fashion stylist for minimalist looks",
                  imageURL: URL(string: "https://styles.redditmedia.com/t5_39er0/styles/communityIcon_rarwqqios5y51.png"),
                  name: "StyleSavvy AI"),
        AISetting(creatorID: 3,
                  desc: "Your guide to fitness and healthy living",
                  imageURL: URL(string: "https://is2-ssl.mzstatic.com/image/thumb/Purple114/v4/51/c6/0e/51c60e7e-c5af-6eef-c18d-7bc0b0bc7209/source/256x256bb.jpg"),
                  name: "FitnessPro AI")
    ]
    
    // Sample ratings (replace with real data)
    let ratings: [String: Double] = [
        "StyleSavvy AI": 4.5,
        "FitnessPro AI": 4.8
    ]
    
    var body: some View {
        NavigationStack {
            if favoriteBots.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No favorites yet.")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Add some from the AI tab!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .navigationTitle("Favorite AI Bots")
            } else {
                AIBotListView(
                    bots: favoriteBots,
                    ratings: ratings,
                    onRemoveFavorite: { bot in
                        favoriteBots.removeAll { $0.name == bot.name }
                    }
                )
                .navigationTitle("Favorite AI Bots")
            }
        }
    }
}
