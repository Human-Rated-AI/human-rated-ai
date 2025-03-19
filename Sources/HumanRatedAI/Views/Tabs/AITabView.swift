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
    // Sample data for the presentation (replace with real data from your backend)
    let aiBots: [AISetting] = [
        AISetting(creatorID: 1,
                  desc: "Your personal fashion stylist for minimalist looks",
                  imageURL: URL(string: "https://styles.redditmedia.com/t5_39er0/styles/communityIcon_rarwqqios5y51.png"),
                  name: "StyleSavvy AI"),
        AISetting(creatorID: 2,
                  desc: "Expert in tech trends and gadgets",
                  imageURL: nil,
                  name: "TechGuru AI"),
        AISetting(creatorID: 3,
                  desc: "Your guide to fitness and healthy living",
                  imageURL: URL(string: "https://is2-ssl.mzstatic.com/image/thumb/Purple114/v4/51/c6/0e/51c60e7e-c5af-6eef-c18d-7bc0b0bc7209/source/256x256bb.jpg"),
                  name: "FitnessPro AI")
    ]
    
    // Sample ratings (replace with real data)
    let ratings: [String: Double] = [
        "StyleSavvy AI": 4.5,
        "TechGuru AI": 4.0,
        "FitnessPro AI": 4.8
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(aiBots, id: \.name) { bot in
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
                                Image(systemName: "person.circle.fill")
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
                                        Image(systemName: star <= fullStars ? "star.fill" : (Double(star - 1) < rating && rating < Double(star) && 0.49999 < fraction) ? "star.leadinghalf.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.black)
            .navigationTitle("AI Bot List")
        }
    }
}
