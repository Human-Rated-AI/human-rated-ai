// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  URL+canOpen.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/31/25.
//

import UIKit

extension URL {
    /// Check if the URL can be opened
    /// - Returns: true if the URL can be opened
    var canOpen: Bool {
#if os(Android)
        ["http", "https"].contains(scheme?.lowercased() ?? "") && host?.notEmptyTrimmed == true
#else
        UIApplication.shared.canOpenURL(self) && host?.notEmptyTrimmed == true
#endif
    }
}
