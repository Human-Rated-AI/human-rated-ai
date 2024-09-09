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
