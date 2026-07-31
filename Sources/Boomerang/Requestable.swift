//
//  File.swift
//  Boomerang
//
//  Created by Øyvind Hauge on 31/07/2026.
//

import Foundation

public enum HttpMethod: String {
    case get = "GET"
    
    case post = "POST"
    
    case put = "PUT"
    
    case patch = "PATCH"
    
    case head = "HEAD"
}

public protocol Requestable {
    
    var method: HttpMethod { get }
    
    var headers: [String: String] { get }
    
    var url: URL { get }
    
    var body: Data? { get }
}

public extension Requestable {
    
    var method: HttpMethod { .get }
    
    var headers: [String: String] { [:] }
}
