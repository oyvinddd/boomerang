//
//  JWT.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation

public struct JWT: Codable, Sendable {
    
    let value: String
    
    let expiresAt: Date
    
    init(_ value: String, expiresAt: Date) {
        self.value = value
        self.expiresAt = expiresAt
    }
}
