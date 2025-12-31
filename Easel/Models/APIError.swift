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
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            switch code {
            case 401:
                return "Unauthorized. Please check your login credentials."
            case 403:
                return "Access denied. You may not have permission to view this content."
            case 404:
                return "Content not found."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "Error \(code): Unable to complete the request."
            }
        }
    }
}


