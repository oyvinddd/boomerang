//
//  AuthManager.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation

public enum AuthState: Sendable {
    // not logged in
    case unauthenticated
    // logged in
    case authenticated(JWT?)
    // token refresh in progress
    case refreshing
}

actor AuthManager {
    
    let authState: AuthState
    let authStateStream: AsyncStream<AuthState>
    
    private let urlSession: URLSession
    private var refreshToken: JWT?
    private var accessToken: JWT?
    private var refreshUrl: URL?
    private var refreshTask: Task<Void, Error>?
    
    private var continuation: AsyncStream<AuthState>.Continuation
    
    init(_ urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        do {
            refreshToken = try KeychainManager.loadRefreshToken()
        } catch {
            print("error loading refresh token from keychain: \(error)")
        }
        
        authState = refreshToken != nil ? .authenticated(nil) : .unauthenticated
        
        let (stream, continuation) = AsyncStream.makeStream(of: AuthState.self)
        self.authStateStream = stream
        self.continuation = continuation
    }
    
    func refresh(after failedAccessToken: JWT) async throws {
        // Somebody else may already have refreshed the token
        // while this request was in flight.
        guard accessToken?.value == failedAccessToken.value else {
            return
        }
        
        guard refreshToken != nil else {
            throw BoomerangError.missingRefreshToken
        }
        
        if let refreshTask {
            try await refreshTask.value
            return
        }
        let task = Task {
            let container = try await performRefresh()
            try setCredentials(container)
        }
        
        refreshTask = task
        
        defer {
            refreshTask = nil
        }
        
        try await task.value
    }
    
    func setRefreshUrl(_ url: URL) {
        refreshUrl = url
    }
    
    func getRefreshToken() -> JWT? {
        return refreshToken
    }
    
    func getAccessToken() -> JWT? {
        return accessToken
    }
    
    func setCredentials(_ container: TokenContainer) throws {
        try KeychainManager.saveRefreshToken(container.refreshToken)
        refreshToken = container.refreshToken
        accessToken = container.accessToken
    }
    
    func clearLocalState() -> Bool {
        refreshToken = nil
        accessToken = nil
        return KeychainManager.deleteRefreshToken()
    }
    
    private func performRefresh() async throws -> TokenContainer {
        let request = try buildRefreshRequest()
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(TokenContainer.self, from: data)
    }
    
    private func buildRefreshRequest() throws -> URLRequest {
        guard let url = refreshUrl else {
            throw BoomerangError.missingRefreshUrl
        }
        guard let token = refreshToken?.value else {
            throw BoomerangError.missingRefreshToken
        }
        return try RequestBuilder(.post, url: url)
            .set(data: TokenRequest(token))
            .build()
    }
}
