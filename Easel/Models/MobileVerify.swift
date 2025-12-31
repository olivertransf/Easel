import Foundation

struct MobileVerifyResponse: Codable {
    let authorized: Bool
    let baseURL: URL?
    let clientId: String?
    let clientSecret: String?
    
    enum CodingKeys: String, CodingKey {
        case authorized
        case baseURL = "base_url"
        case clientId = "client_id"
        case clientSecret = "client_secret"
    }
}

struct OAuthTokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let token_type: String
    let expires_in: TimeInterval?
    let user: OAuthUser
    let canvas_region: String?
    
    struct RealUser: Codable {
        let id: String
        let name: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            
            if let intId = try? container.decode(Int.self, forKey: .id) {
                id = String(intId)
            } else {
                id = try container.decode(String.self, forKey: .id)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name
        }
    }
    let real_user: RealUser?
}

struct OAuthUser: Codable {
    let id: String
    let name: String
    let effective_locale: String
    let email: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        effective_locale = try container.decode(String.self, forKey: .effective_locale)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, effective_locale, email
    }
}

