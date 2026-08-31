//
//  TokenRequest.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 31/08/2026.
//

import Foundation

struct TokenRequest: Encodable {
    
    let refreshToken: String
    
    init(_ refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
