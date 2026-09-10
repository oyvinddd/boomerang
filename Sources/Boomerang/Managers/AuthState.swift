//
//  AuthState.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 10/09/2026.
//

import Foundation

public enum AuthState: Sendable, Equatable {
    // not logged in
    case unauthenticated
    // logged in
    case authenticated(JWT?)
    // token refresh in progress
    case refreshing
    
    public static func == (_ lhs: AuthState, _ rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.refreshing, .refreshing):
            return true
            case (.authenticated, .authenticated):
            return true
        default:
            return false
        }
    }
}
