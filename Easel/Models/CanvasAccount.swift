import Foundation
import Combine

struct CanvasAccount: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let domain: String
    let authenticationProvider: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case domain
        case authenticationProvider = "authentication_provider"
    }
    
    init(name: String, domain: String, authenticationProvider: String?) {
        self.id = domain
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.domain = domain
        self.authenticationProvider = authenticationProvider
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name).trimmingCharacters(in: .whitespacesAndNewlines)
        domain = try container.decode(String.self, forKey: .domain)
        var auth = try container.decodeIfPresent(String.self, forKey: .authenticationProvider)
        if auth?.isEmpty == true || auth == "Null" {
            auth = nil
        }
        authenticationProvider = auth
        id = domain
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(domain, forKey: .domain)
        try container.encodeIfPresent(authenticationProvider, forKey: .authenticationProvider)
    }
}

