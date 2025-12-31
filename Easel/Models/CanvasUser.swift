//
//  CanvasUser.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasUser: Codable {
    let id: Int
    let name: String
    let sortable_name: String?
    let short_name: String?
    let login_id: String?
    let email: String?
}


