//
//  APIError.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
}


