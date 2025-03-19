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

// Import our reusable component

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
            AIBotListView(bots: aiBots, ratings: ratings)
                .navigationTitle("AI Bot List")
        }
    }
}
