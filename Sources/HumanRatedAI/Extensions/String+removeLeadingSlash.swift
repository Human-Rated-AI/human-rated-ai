// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  String+removeLeadingSlash.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/31/25.
//

extension String {
    func removeLeadingSlash() -> String {
        if hasPrefix("/") {
            return String(dropFirst())
        }
        return self
    }
}
