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

public struct Boomerang {
    
    private static let session: URLSession = .shared
        
    private init() {} // make struct non-instanciable
    
    public static func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        let (data, _) = try await executeRequest(request)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public static func post<T: Decodable>(_ request: Requestable) async throws -> T {
        let (data, _) = try await executeRequest(RequestFactory(request).build())
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public static func execute<T: Decodable>(_ request: Requestable) async throws -> T {
        let (data, _) = try await executeRequest(RequestFactory(request).build())
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public static func execute(_ request: Requestable) async throws {
        _ = try await executeRequest(RequestFactory(request).build())
    }
    
    private static func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, res) = try await session.data(for: request)
        
        guard let httpResponse = res as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(httpResponse.statusCode)
        }
        return (data, httpResponse)
    }
}
