// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  String+nonEmpty.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/2/25.
//

import Foundation

extension String {
    var isEmptyTrimmed: Bool {
        trimmed.isEmpty
    }
    
    var nonEmpty: Self? {
        isEmpty ? nil : self
    }
    
    var nonEmptyTrimmed: String? {
        trimmed.nonEmpty
    }
    
    var notEmpty: Bool {
        !isEmpty
    }
    
    var notEmptyTrimmed: Bool {
        trimmed.notEmpty
    }
    
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
