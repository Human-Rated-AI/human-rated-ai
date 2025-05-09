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

public struct AISetting: Codable, Identifiable {
    // Firestore document ID
    public var id: String = UUID().uuidString
    var caption: String?        // "Please describe what you see on this picture..."
    var desc: String?
    var imageURL: URL?
    var isOpenSource = false    // True if bot settings are visible to all users
    var isPublic = false        // True if this bot is visible to all users
    var name: String
    var prefix: String?         // "You are..."
    var suffix: String?
    var welcome: String?        // "\n\nWelcome!\n\nI’m your..."
    
    var trimmed: AISetting {
        AISetting(id: id,
                  caption: caption?.nonEmptyTrimmed,
                  desc: desc?.nonEmptyTrimmed,
                  imageURL: imageURL,
                  isOpenSource: isOpenSource,
                  isPublic: isPublic,
                  name: name.trimmed,
                  prefix: prefix?.nonEmptyTrimmed,
                  suffix: suffix?.nonEmptyTrimmed,
                  welcome: welcome?.nonEmptyTrimmed)
    }
    
    enum CodingKeys: String, CodingKey {
        case caption
        case desc = "description"
        case id, imageURL, isOpenSource, isPublic, name, prefix, suffix, welcome
    }
}

public typealias AISettings = [AISetting]

public extension AISetting {
    mutating func update(_ key: String, with value: Any) {
        let boolValue = value as? Bool
        let stringValue = value as? String
        switch AISetting.CodingKeys(rawValue: key) {
        case .caption:
            caption = stringValue
        case .desc:
            desc = stringValue
        case .imageURL:
            imageURL = stringValue?.asURL
        case .isOpenSource:
            isOpenSource = boolValue ?? false
        case .isPublic:
            isPublic = boolValue ?? false
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

extension AISetting: Comparable {
    public static func < (lhs: AISetting, rhs: AISetting) -> Bool {
        guard lhs.isPublic == rhs.isPublic else { return lhs.isPublic }
        guard lhs.isOpenSource == rhs.isOpenSource else { return lhs.isOpenSource }
        let lhsName = lhs.name.trimmed
        let rhsName = rhs.name.trimmed
        guard lhsName.notEmpty else { return false }
        guard rhsName.notEmpty else { return true }
        guard lhsName == rhsName else { return lhsName < rhsName }
        let lhsDesc = lhs.desc?.trimmed ?? ""
        let rhsDesc = rhs.desc?.trimmed ?? ""
        guard lhsDesc.notEmpty else { return false }
        guard rhsDesc.notEmpty else { return true }
        guard lhsDesc == rhsDesc else { return lhsDesc < rhsDesc }
        return lhs.id < rhs.id
    }
}

extension AISetting: Equatable {
    public static func == (lhs: AISetting, rhs: AISetting) -> Bool {
        lhs.id == rhs.id
    }
}

extension AISetting: Hashable {}
