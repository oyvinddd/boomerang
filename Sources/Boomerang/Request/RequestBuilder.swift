//
//  RequestBuilder.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 31/07/2026.
//

import Foundation

final class RequestBuilder {
    
    var method: HttpMethod
    
    var url: URL
    
    var headers: [String: String]?
    
    var body: Data?
    
    init(_ request: Requestable) {
        self.method = request.method
        self.headers = request.headers
        self.url = request.url
        self.body = request.body
    }
    
    init(_ method: HttpMethod, url: URL) {
        self.method = method
        self.url = url
    }
    
    @discardableResult
    func set(value: String, for header: String) -> Self {
        if headers == nil {
            headers = [header: value]
        }
        headers?[header] = value
        return self
    }
    
    @discardableResult
    func set(accessToken: String?) -> Self {
        guard let accessToken else {
            return self
        }
        set(value: "Bearer \(accessToken)", for: "Authorization")
        return self
    }
    
    @discardableResult
    func set(body: Data?) -> Self {
        self.body = body
        return self
    }
    
    @discardableResult
    func set(data: Encodable) throws -> Self {
        self.body = try JSONEncoder().encode(data)
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
