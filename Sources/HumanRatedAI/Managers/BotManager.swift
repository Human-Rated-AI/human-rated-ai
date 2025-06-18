// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  BotManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 6/18/25.
//

import Combine

// Create a simple observable wrapper for the bot
class BotManager: ObservableObject {
    @Published var bot: AISetting
    
    init(bot: AISetting) {
        self.bot = bot
    }
    
    func updateBot(_ newBot: AISetting) {
        bot = newBot
    }
}
