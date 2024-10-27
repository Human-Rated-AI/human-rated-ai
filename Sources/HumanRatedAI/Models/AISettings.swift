// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AISettings.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 10/27/24.
//

import Foundation

public struct AISetting: Codable {
    var caption: String?    // "Please describe what you see on this picture..."
    let creatorID: Int
    var desc: String?
    var imageURL: URL?
    var name: String
    var prefix: String?     // "You are..."
    var suffix: String?
    var welcome: String?    // "\n\nWelcome!\n\nI’m your..."
    
    enum CodingKeys: String, CodingKey {
        case caption, creatorID
        case desc = "description"
        case imageURL, name, prefix, suffix, welcome
    }
}

public typealias AISettings = [AISetting]

public extension AISetting {
    mutating func update(_ key: String, with value: Any) {
        let stringValue = value as? String
        switch AISetting.CodingKeys(rawValue: key) {
        case .caption:
            caption = stringValue
        case .creatorID:
            break
        case .desc:
            desc = stringValue
        case .imageURL:
            imageURL = stringValue?.asURL
        case .name:
            guard let stringValue else { break }
            name = stringValue
        case .prefix:
            `prefix` = stringValue
        case .suffix:
            suffix = stringValue
        case .welcome:
            welcome = stringValue
        default:
            break
        }
    }
    
    mutating func update(with dictionary: [String: Any]) {
        dictionary.forEach { update($0.key, with: $0.value) }
    }
}
