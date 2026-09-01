//
//  BoomerangError.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 31/08/2026.
//

enum BoomerangError: Error {
    
    case invalidResponse
    
    case missingRefreshUrl
    
    case missingRefreshToken
    
    case missingAccessToken
    
    case invalidStatusCode(Int)
}
