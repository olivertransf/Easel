//
//  CanvasEnrollment.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasEnrollment: Codable, Identifiable {
    let id: String
    let userId: String?
    let courseId: String?
    let type: String
    let role: String?
    let roleId: String?
    let enrollmentState: String?
    let user: CanvasCourseUser?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case courseId = "course_id"
        case type
        case role
        case roleId = "role_id"
        case enrollmentState = "enrollment_state"
        case user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        type = try container.decode(String.self, forKey: .type)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        enrollmentState = try container.decodeIfPresent(String.self, forKey: .enrollmentState)
        user = try container.decodeIfPresent(CanvasCourseUser.self, forKey: .user)
        
        if let intUserId = try? container.decode(Int.self, forKey: .userId) {
            userId = String(intUserId)
        } else {
            userId = try container.decodeIfPresent(String.self, forKey: .userId)
        }
        
        if let intCourseId = try? container.decode(Int.self, forKey: .courseId) {
            courseId = String(intCourseId)
        } else {
            courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        }
        
        if let intRoleId = try? container.decode(Int.self, forKey: .roleId) {
            roleId = String(intRoleId)
        } else {
            roleId = try container.decodeIfPresent(String.self, forKey: .roleId)
        }
    }
}

struct CanvasCourseUser: Codable, Identifiable {
    let id: String
    let name: String
    let sortableName: String?
    let shortName: String?
    let loginId: String?
    let email: String?
    let avatarUrl: String?
    let pronouns: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortableName = "sortable_name"
        case shortName = "short_name"
        case loginId = "login_id"
        case email
        case avatarUrl = "avatar_url"
        case pronouns
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        sortableName = try container.decodeIfPresent(String.self, forKey: .sortableName)
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName)
        loginId = try container.decodeIfPresent(String.self, forKey: .loginId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        pronouns = try container.decodeIfPresent(String.self, forKey: .pronouns)
    }
}

