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
}
