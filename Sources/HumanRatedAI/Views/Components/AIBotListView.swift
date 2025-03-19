// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AIBotListView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/19/25.
//

import SwiftUI

struct AIBotListView: View {
    let bots: [AISetting]
    let ratings: [String: Double]
    var onRemoveFavorite: ((AISetting) -> Void)? = nil
    
    var body: some View {
        List {
            ForEach(bots, id: \.name) { bot in
                NavigationLink(destination: Text("Chat with \(bot.name)")) { // Placeholder destination
                    HStack(spacing: 15) {
                        // Image or placeholder
                        if let imageURL = bot.imageURL {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        
                        // Bot details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(bot.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(bot.desc ?? "No description available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            // Rating
                            HStack(spacing: 3) {
                                let rating = ratings[bot.name] ?? Double(0)
                                ForEach(1...5, id: \.self) { star in
                                    let fullStars = Int(rating)
                                    let fraction = rating - Double(fullStars)
                                    if star <= fullStars {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    } else if Double(star - 1) < rating && rating < Double(star) && 0.49999 < fraction {
#if os(Android)
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
#else
                                        Image(systemName: "star.leadinghalf.fill")
                                            .foregroundColor(.yellow)
#endif
                                    } else {
                                        Image(systemName: "star")
#if os(Android)
                                            .foregroundColor(.gray)
#else
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
                        
                        // Remove from favorites button (only shown when callback is provided)
                        if let onRemove = onRemoveFavorite {
                            Button(action: {
                                onRemove(bot)
                            }) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.black)
    }
}
