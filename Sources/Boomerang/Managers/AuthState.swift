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
    case authenticated
    // token refresh in progress
    case refreshing
}
