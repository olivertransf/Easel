//
//  CanvasEnrollment.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasEnrollment: Codable, Identifiable {
    let idRaw: String?
    let userId: String?
    let courseId: String?
    let type: String
    let role: String?
    let roleId: String?
    let enrollmentState: String?
    let user: CanvasCourseUser?
    let currentGrade: String?
    let computedCurrentGrade: String?
    let computedFinalGrade: String?
    let computedCurrentScore: Double?
    let computedFinalScore: Double?
    let grades: EnrollmentGrades?
    
    var id: String {
        idRaw ?? "\(courseId ?? "unknown")-\(userId ?? "unknown")-\(type)"
    }
    
    enum CodingKeys: String, CodingKey {
        case idRaw = "id"
        case userId = "user_id"
        case courseId = "course_id"
        case type
        case role
        case roleId = "role_id"
        case enrollmentState = "enrollment_state"
        case user
        case currentGrade = "current_grade"
        case computedCurrentGrade = "computed_current_grade"
        case computedFinalGrade = "computed_final_grade"
        case computedCurrentScore = "computed_current_score"
        case computedFinalScore = "computed_final_score"
        case grades
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .idRaw) {
            idRaw = String(intId)
        } else {
            idRaw = try container.decodeIfPresent(String.self, forKey: .idRaw)
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
        
        currentGrade = try container.decodeIfPresent(String.self, forKey: .currentGrade)
        computedCurrentGrade = try container.decodeIfPresent(String.self, forKey: .computedCurrentGrade)
        computedFinalGrade = try container.decodeIfPresent(String.self, forKey: .computedFinalGrade)
        computedCurrentScore = try container.decodeIfPresent(Double.self, forKey: .computedCurrentScore)
        computedFinalScore = try container.decodeIfPresent(Double.self, forKey: .computedFinalScore)
        grades = try container.decodeIfPresent(EnrollmentGrades.self, forKey: .grades)
    }
}

struct EnrollmentGrades: Codable {
    let currentGrade: String?
    let finalGrade: String?
    let currentScore: Double?
    let finalScore: Double?
    let unpostedCurrentGrade: String?
    let unpostedFinalGrade: String?
    let unpostedCurrentScore: Double?
    let unpostedFinalScore: Double?
    let htmlUrl: String?
    let locked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case currentGrade = "current_grade"
        case finalGrade = "final_grade"
        case currentScore = "current_score"
        case finalScore = "final_score"
        case unpostedCurrentGrade = "unposted_current_grade"
        case unpostedFinalGrade = "unposted_final_grade"
        case unpostedCurrentScore = "unposted_current_score"
        case unpostedFinalScore = "unposted_final_score"
        case htmlUrl = "html_url"
        case locked
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

