//
//  TokenContainer.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation

public struct TokenContainer: Codable, Sendable {
    
    let refreshToken: JWT
    
    let accessToken: JWT
    
    public init(_ refreshToken: JWT, _ accessToken: JWT) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
    }
}
