//
//  TokenResponse.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int?
    let refresh_token: String?
}


