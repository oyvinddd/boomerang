//
//  RequestFactory.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 31/07/2026.
//

import Foundation

struct RequestFactory {
    
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
