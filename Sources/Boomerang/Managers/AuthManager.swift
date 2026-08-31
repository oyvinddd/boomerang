//
//  AuthManager.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 27/08/2026.
//

import Foundation

enum AuthManagerError: Error {
    
    case missingRefreshUrl
    
    case missingRefreshToken
    
    case tokenRefreshFailed
}

actor AuthManager {
    
    private let urlSession: URLSession
    private var refreshToken: JWT?
    private var accessToken: JWT?
    private var refreshUrl: URL?
    private var refreshTask: Task<Void, Error>?
    
    init(_ urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        do {
            refreshToken = try KeychainManager.loadRefreshToken()
        } catch {
            print("error loading refresh token from keychain: \(error)")
        }
    }
    
    func refreshIfNeeded() async throws {
        if let refreshTask {
            try await refreshTask.value
            return
        }
        let task = Task {
            try await performRefresh()
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
    
    private func performRefresh() async throws {
        let request = try buildRefreshRequest()
        let (data, _) = try await urlSession.data(for: request)
        let container = try JSONDecoder().decode(TokenContainer.self, from: data)
        try setCredentials(container)
    }
}

extension AuthManager {
    
    private func buildRefreshRequest() throws -> URLRequest {
        guard let url = refreshUrl else {
            throw AuthManagerError.missingRefreshUrl
        }
        guard let token = refreshToken?.value else {
            throw AuthManagerError.missingRefreshToken
        }
        return try RequestBuilder(.post, url: url)
            .set(data: TokenRequest(token))
            .build()
    }
}
