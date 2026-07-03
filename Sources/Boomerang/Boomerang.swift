//
//  Boomerang.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 28/04/2026.
//

import Foundation

public protocol Requestable {
    
    var method: Method { get }
    
    var headers: [String: String] { get }
    
    var url: URL { get }
    
    var body: Data? { get }
}

public enum NetworkError: Error {
    case noDataAvailableFromServer
    case invalidStatusCode(Int)
    case unableToDecodeData
    case invalidResponse
}

public enum Method: String {
    case get = "GET"
    
    case post = "POST"
    
    case put = "PUT"
    
    case patch = "PATCH"
    
    case head = "HEAD"
}

public struct Boomerang {
    
    private static let session: URLSession = .shared
        
    private init() {} // make struct non-instanciable
    
    public static func post<T: Decodable>(_ request: Requestable) async throws -> T? {
        let (data, _) = try await executeRequest(RequestFactory(request).build())
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public static func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await executeRequest(request)
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

// MARK: - Request factory

internal struct RequestFactory {
    
    var method: Method
    
    var url: URL
    
    var headers: [String: String]?
    
    var body: Data?
    
    init(_ request: Requestable) {
        self.method = request.method
        self.headers = request.headers
        self.url = request.url
        self.body = request.body
    }
    
    init(_ method: Method, url: URL) {
        self.method = method
        self.url = url
    }
    
    mutating func set(body: Data?) -> Self {
        self.body = body
        return self
    }
    
    func build() -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpBody = body
        return urlRequest
    }
}
