//
//  AuthManager.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation

actor AuthManager {
    
    let authStateStream: AsyncStream<AuthState>
    
    private let urlSession: URLSession
    
    private(set) var authState: AuthState
    private(set) var refreshToken: JWT?
    private(set) var accessToken: JWT?
    
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
        
        authState = refreshToken != nil ? .authenticated : .unauthenticated
        
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
        
        setAuthState(.refreshing)
        
        let task = Task {
            do {
                let container = try await performRefresh()
                try setCredentials(container)
                
            } catch {
                clearLocalState()
                throw error
            }
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
    
    func setCredentials(_ container: TokenContainer) throws {
        try KeychainManager.saveRefreshToken(container.refreshToken)
        refreshToken = container.refreshToken
        accessToken = container.accessToken
        setAuthState(.authenticated)
    }
    
    func clearLocalState() {
        refreshToken = nil
        accessToken = nil
        setAuthState(.unauthenticated)
        _ = KeychainManager.deleteRefreshToken()
    }
    
    private func setAuthState(_ state: AuthState) {
        authState = state
        continuation.yield(state)
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
