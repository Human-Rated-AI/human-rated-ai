// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  EnvironmentManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 9/22/24.
//

import SwiftUI

// MARK: - Generic
class EnvironmentManager: ObservableObject {
    var keys: [String] { [String](variables.keys) }
    let variables: [String: String?]
    
    private init(filename: String, keys: [String]) {
        self.variables = EnvironmentManager.variables(from: filename, keys: keys)
    }
}

// MARK: - AI
extension EnvironmentManager {
    private struct Keys {
        static let aiKey = "AI_KEY"
        static let aiModel = "AI_MODEL"
        static let aiURL = "AI_URL"
    }
    static var ai: EnvironmentManager {
        EnvironmentManager(filename: "env", keys: [Keys.aiKey, Keys.aiModel, Keys.aiURL])
    }
    var aiKey: String? { variables[Keys.aiKey] ?? nil }
    var aiModel: String? { variables[Keys.aiModel] ?? nil }
    var aiURL: URL? { (variables[Keys.aiURL] ?? nil)?.asURL }
    
}

private extension EnvironmentManager {
    static func variables(from filename: String, keys: [String]) -> [String: String?] {
        guard let envFileURL = Bundle.module.url(forResource: filename, withExtension: nil),
              let contents = try? String(contentsOf: envFileURL) else { return [:] }
        return parseEnvFile(contents: contents, keys: keys)
    }
    
    static func parseEnvFile(contents: String, keys: [String]) -> [String: String?] {
        var envVars = [String: String?]()
        let lines = contents.split(separator: "\n")
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("#") { continue }
            if let rangeOfEquals = trimmedLine.rangeOfUnquotedString("=") {
                let keyPart = String(trimmedLine[..<rangeOfEquals.lowerBound])
                let valuePart = String(trimmedLine[rangeOfEquals.upperBound...])
                let key = keyPart.trimmingCharacters(in: .whitespacesAndNewlines)
                if keys.contains(key) {
                    var valueWithoutComment = valuePart
                    if let rangeOfHashes = valuePart.rangeOfUnquotedString("#") {
                        valueWithoutComment = String(valuePart[..<(rangeOfHashes.lowerBound)])
                    }
                    var value = valueWithoutComment.trimmingCharacters(in: .whitespacesAndNewlines)
                    if value.first == "\"" && value.last == "\"" {
                        value = String(value.dropFirst().dropLast())
                    }
                    envVars[key] = value
                }
            }
            for key in keys {
                if envVars[key] == nil {
                    envVars[key] = nil
                }
            }
        }
        return envVars
    }
}

private extension String {
    func rangeOfUnquotedString(_ searchString: String) -> Range<String.Index>? {
        var isInQuotes = false
        var index = startIndex
        while index < endIndex {
            if self[index] == "\"" {
#if SKIP
                isInQuotes = !isInQuotes
#else
                isInQuotes.toggle()
#endif
            } else if self[index...].hasPrefix(searchString) && !isInQuotes {
                return index ..< self.index(index, offsetBy: searchString.count)
            }
            index = self.index(after: index)
        }
        return nil
    }
}
