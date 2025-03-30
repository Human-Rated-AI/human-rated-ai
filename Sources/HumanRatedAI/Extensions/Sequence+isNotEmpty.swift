// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  Sequence+isNotEmpty.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/30/25.
//

extension Sequence {
    var isNotEmpty: Bool { 0 < count(where: { _ in true }) }
}
