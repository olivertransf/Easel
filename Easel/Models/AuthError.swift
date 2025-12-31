//
//  AuthError.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case invalidURL
    case tokenExchangeFailed
    case sessionExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        case .sessionExtractionFailed:
            return "Failed to extract session token"
        }
    }
}


