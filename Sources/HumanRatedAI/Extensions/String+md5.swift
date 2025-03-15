// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  String+md5.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 9/22/24.
//

#if !os(Android)
import CryptoKit
#endif
import Foundation

extension String {
    var md5: String {
#if os(Android)
        // SKIP INSERT:
        // val md = java.security.MessageDigest.getInstance("MD5")
        // md.update(this.toByteArray(java.nio.charset.StandardCharsets.UTF_8))
        // val digest = md.digest()
        // val sb = StringBuilder()
        // for (b in digest) {
        //     sb.append(String.format("%02x", b))
        // }
        // val hash = sb.toString()
        // return hash
#else
        let digest = Insecure.MD5.hash(data: Data(utf8))
        let hash = digest.map { String(format: "%02hhx", $0) }.joined()
        return hash
#endif
    }
    
    var sha256: String {
#if os(Android)
        // SKIP INSERT:
        // val md = java.security.MessageDigest.getInstance("SHA-256")
        // md.update(this.toByteArray(java.nio.charset.StandardCharsets.UTF_8))
        // val digest = md.digest()
        // val sb = StringBuilder()
        // for (b in digest) {
        //     sb.append(String.format("%02x", b))
        // }
        // val hash = sb.toString()
        // return hash
#else
        let data = Data(utf8)
        let digest = SHA256.hash(data: data)
        let hash = digest.map { String(format: "%02hhx", $0) }.joined()
        return hash
#endif
    }
}
