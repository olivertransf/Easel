//
//  CanvasUser.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasUser: Codable {
    let id: String
    let name: String
    let sortable_name: String?
    let short_name: String?
    let login_id: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortable_name
        case short_name
        case login_id
        case email
    }
    
    init(id: String, name: String, sortable_name: String? = nil, short_name: String? = nil, login_id: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.sortable_name = sortable_name
        self.short_name = short_name
        self.login_id = login_id
        self.email = email
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idValue = try container.decode(AnyCodableValue.self, forKey: .id)
        id = idValue.stringValue
        
        name = try container.decode(String.self, forKey: .name)
        sortable_name = try container.decodeIfPresent(String.self, forKey: .sortable_name)
        short_name = try container.decodeIfPresent(String.self, forKey: .short_name)
        login_id = try container.decodeIfPresent(String.self, forKey: .login_id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
    }
}


