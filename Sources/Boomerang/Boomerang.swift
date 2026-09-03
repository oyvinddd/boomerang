//
//  Boomerang.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 28/04/2026.
//

import Foundation

public actor Boomerang {
    
    public static let shared = Boomerang()
    
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    
    private var authManager: AuthManager
    private var globalRequestHeaders: [String: String]?
        
    init(urlSession: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.urlSession = urlSession
        self.jsonDecoder = decoder
        self.authManager = .init(urlSession)
    }
    
    // MARK: - Public API
    
    public func execute<T: Decodable>(_ request: Requestable) async throws -> T {
        let (data, _) = try await executeRequestAndRetry(request)
        return try jsonDecoder.decode(T.self, from: data)
    }
    
    public func execute(_ request: Requestable) async throws {
        try await executeRequestAndRetry(request)
    }
    
    // MARK: - Private functions
    
    @discardableResult
    private func executeRequestAndRetry(_ request: Requestable) async throws -> (Data, HTTPURLResponse) {
        let response = try await executeRequest(request)
        
        if response.1.statusCode == 401 && request.authRequirement == .bearerToken {
            guard let accessToken = response.2 else {
                throw BoomerangError.missingAccessToken
            }
            
            try await authManager.refresh(after: accessToken)
            
            let retryResponse = try await executeRequest(request)
            
            try validateResponse(retryResponse.1)
            return (retryResponse.0, retryResponse.1)
        }

        try validateResponse(response.1)
        return (response.0, response.1)
    }
    
    private func executeRequest(_ request: Requestable) async throws -> (Data, HTTPURLResponse, JWT?) {
        let builder = RequestBuilder(request)
        var accessToken: JWT?
        
        if request.authRequirement == .bearerToken {
            accessToken = await authManager.getAccessToken()
            builder.set(accessToken: accessToken?.value)
        }
        
        let (data, res) = try await urlSession.data(for: builder.build())
        
        guard let httpResponse = res as? HTTPURLResponse else {
            throw BoomerangError.invalidResponse
        }
        
        return (data, httpResponse, accessToken)
    }
    
    private func validateResponse(_ response: HTTPURLResponse) throws {
        guard (200..<300).contains(response.statusCode) else {
            throw BoomerangError.invalidStatusCode(response.statusCode)
        }
    }
}

// MARK: - Public utils

extension Boomerang {
    
    public func setRefreshTokenUrl(_ url: URL) async {
        await authManager.setRefreshUrl(url)
    }
    
    public func setCredentials(_ container: TokenContainer) async throws {
        try await authManager.setCredentials(container)
    }
    
    public func clearLocalAuthState() async {
        _ = await authManager.clearLocalState()
    }
}
