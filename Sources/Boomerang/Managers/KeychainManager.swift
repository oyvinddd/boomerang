//
//  KeychainManager.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation
import Security

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case dataNotFound
    case dataCorrupt
}

struct KeychainManager {
    
    private static let attrService = Bundle.main.bundleIdentifier ?? "acme.boomerang.secure"
    private static let attrAccount = "token" // the refresh token
    
    static func saveRefreshToken(_ refreshToken: JWT) throws {
        let data = try JSONEncoder().encode(refreshToken)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: attrService,
            kSecAttrAccount as String: attrAccount
        ]

        // Remove existing item if present
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: attrService,
            kSecAttrAccount as String: attrAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static func loadRefreshToken() throws -> JWT {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: attrService,
            kSecAttrAccount as String: attrAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?

        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw KeychainError.dataNotFound
            }
            
            do {
                
                return try JSONDecoder().decode(JWT.self, from: data)
                
            } catch {
                throw KeychainError.dataCorrupt
            }

        case errSecItemNotFound:
            throw KeychainError.dataNotFound

        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static func deleteRefreshToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: attrService,
            kSecAttrAccount as String: attrAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
