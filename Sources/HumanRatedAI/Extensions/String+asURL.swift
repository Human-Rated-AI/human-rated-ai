// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  String+asURL.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 9/22/24.
//

import Foundation

extension String {
    var asURL: URL? {
        URL(string: self)
    }
}
