//
//  NonceGenerator.swift
//  Yona
//
//  A random nonce for Sign in with Apple. Apple signs the SHA-256 hash of the nonce
//  into the identity token; Supabase verifies it against the raw nonce we pass to
//  `signInWithIdToken`, preventing replay attacks.
//

import CryptoKit
import Foundation

enum NonceGenerator {
    /// A cryptographically random URL-safe string.
    static func random(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var byte: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
                return byte
            }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    /// Lowercase hex SHA-256 of the input — the value sent in the Apple request.
    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
