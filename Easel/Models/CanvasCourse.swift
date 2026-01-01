//
//  CanvasCourse.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

enum CourseDefaultView: String, Codable {
    case assignments
    case feed
    case modules
    case syllabus
    case wiki
}

struct CanvasCourse: Codable, Identifiable {
    let id: String
    let name: String?
    let courseCode: String?
    let startAt: String?
    let endAt: String?
    let enrollmentTermId: String?
    let totalStudents: Int?
    let workflowState: String?
    let isFavorite: Bool?
    let syllabusBody: String?
    let defaultView: CourseDefaultView?
    let enrollments: [CanvasEnrollment]?
    
    var displayName: String {
        name ?? courseCode ?? "Untitled Course"
    }
    
    var currentGrade: String? {
        guard let enrollment = enrollments?.first(where: { $0.type == "StudentEnrollment" || $0.type == "student" }) else {
            return nil
        }
        return enrollment.grades?.currentGrade ?? 
               enrollment.grades?.finalGrade ??
               enrollment.computedCurrentGrade ?? 
               enrollment.currentGrade
    }
    
    var currentScorePercentage: Double? {
        guard let enrollment = enrollments?.first(where: { $0.type == "StudentEnrollment" || $0.type == "student" }) else {
            return nil
        }
        return enrollment.grades?.currentScore ?? 
               enrollment.grades?.finalScore ??
               enrollment.computedCurrentScore ??
               enrollment.computedFinalScore
    }
    
    var isGradeLocked: Bool {
        enrollments?.first(where: { $0.type == "StudentEnrollment" || $0.type == "student" })?.grades?.locked ?? false
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case startAt = "start_at"
        case endAt = "end_at"
        case enrollmentTermId = "enrollment_term_id"
        case totalStudents = "total_students"
        case workflowState = "workflow_state"
        case isFavorite = "is_favorite"
        case syllabusBody = "syllabus_body"
        case defaultView = "default_view"
        case enrollments
    }
    
    init(
        id: String,
        name: String? = nil,
        courseCode: String? = nil,
        startAt: String? = nil,
        endAt: String? = nil,
        enrollmentTermId: String? = nil,
        totalStudents: Int? = nil,
        workflowState: String? = nil,
        isFavorite: Bool? = nil,
        syllabusBody: String? = nil,
        defaultView: CourseDefaultView? = nil,
        enrollments: [CanvasEnrollment]? = nil
    ) {
        self.id = id
        self.name = name
        self.courseCode = courseCode
        self.startAt = startAt
        self.endAt = endAt
        self.enrollmentTermId = enrollmentTermId
        self.totalStudents = totalStudents
        self.workflowState = workflowState
        self.isFavorite = isFavorite
        self.syllabusBody = syllabusBody
        self.defaultView = defaultView
        self.enrollments = enrollments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decodeIfPresent(String.self, forKey: .name)
        courseCode = try container.decodeIfPresent(String.self, forKey: .courseCode)
        startAt = try container.decodeIfPresent(String.self, forKey: .startAt)
        endAt = try container.decodeIfPresent(String.self, forKey: .endAt)
        totalStudents = try container.decodeIfPresent(Int.self, forKey: .totalStudents)
        workflowState = try container.decodeIfPresent(String.self, forKey: .workflowState)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite)
        syllabusBody = try container.decodeIfPresent(String.self, forKey: .syllabusBody)
        defaultView = try container.decodeIfPresent(CourseDefaultView.self, forKey: .defaultView)
        enrollments = try container.decodeIfPresent([CanvasEnrollment].self, forKey: .enrollments)
        
        if let intTermId = try? container.decode(Int.self, forKey: .enrollmentTermId) {
            enrollmentTermId = String(intTermId)
        } else {
            enrollmentTermId = try container.decodeIfPresent(String.self, forKey: .enrollmentTermId)
        }
    }
}

struct CanvasPage: Codable {
    let url: String
    let title: String
    var body: String?
    let frontPage: Bool?
    let published: Bool?
    
    enum CodingKeys: String, CodingKey {
        case url
        case title
        case body
        case frontPage = "front_page"
        case published
    }
}


