//
//  Boomerang.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 28/04/2026.
//

import Foundation

public enum NetworkError: Error {
    case noDataAvailableFromServer
    case invalidStatusCode(Int)
    case unableToDecodeData
    case invalidResponse
}

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
        let (data, _) = try await executeRequest(request)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func execute(_ request: Requestable) async throws {
        try await executeRequest(request)
    }
    
    // MARK: - Private functions
    
    @discardableResult
    private func executeRequest(_ request: Requestable) async throws -> (Data, HTTPURLResponse) {
        let builder = RequestBuilder(request)
        
        if request.authRequirement == .bearerToken {
            try await authManager.refreshIfNeeded()
            let token = await authManager.getRefreshToken()?.value
            builder.set(refreshToken: token)
        }
        
        let (data, res) = try await urlSession.data(for: builder.build())
        
        guard let httpResponse = res as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(httpResponse.statusCode)
        }
        return (data, httpResponse)
    }
}

// MARK: - Public utils

extension Boomerang {
    
    public func setRefreshTokenUrl(_ url: URL) async {
        await authManager.setRefreshUrl(url)
    }
    
    public func setCredentials(_ refreshToken: JWT, _ accessToken: JWT) async throws {
        let container = TokenContainer(refreshToken: refreshToken, accessToken: accessToken)
        try await authManager.setCredentials(container)
    }
    
    public func clearLocalAuthState() async {
        _ = await authManager.clearLocalState()
    }
}
