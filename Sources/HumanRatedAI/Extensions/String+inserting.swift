// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  String+inserting.swift
//  Human Rated AI
//
//  Created by Denis Bystruev on 9/9/24.
//

extension String {
    func inserting(_ insert: String, at indexes: [Int]) -> String {
        var inputIndexes = indexes
        var new = ""
        for (index, char) in enumerated() {
            if index == inputIndexes.first {
                new += "\(insert)\(char)"
                inputIndexes.removeFirst()
            } else {
                new += "\(char)"
            }
        }
        return new
    }
}
