//
//  CanvasSubmission.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasSubmission: Codable {
    let id: String
    let assignmentId: String
    let userId: String
    let submittedAt: Date?
    let grade: String?
    let score: Double?
    let workflowState: String
    let submissionType: String?
    let body: String?
    let attachments: [CanvasFile]?
    let submissionComments: [CanvasSubmissionComment]?
    let rubricAssessment: [String: CanvasRubricCriterionAssessment]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case assignmentId = "assignment_id"
        case userId = "user_id"
        case submittedAt = "submitted_at"
        case grade
        case score
        case workflowState = "workflow_state"
        case submissionType = "submission_type"
        case body
        case attachments
        case submissionComments = "submission_comments"
        case rubricAssessment = "rubric_assessment"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idValue = try container.decode(AnyCodableValue.self, forKey: .id)
        id = idValue.stringValue
        
        let assignmentIdValue = try container.decode(AnyCodableValue.self, forKey: .assignmentId)
        assignmentId = assignmentIdValue.stringValue
        
        let userIdValue = try container.decode(AnyCodableValue.self, forKey: .userId)
        userId = userIdValue.stringValue
        
        submissionType = try container.decodeIfPresent(String.self, forKey: .submissionType)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        attachments = try container.decodeIfPresent([CanvasFile].self, forKey: .attachments)
        submissionComments = try container.decodeIfPresent([CanvasSubmissionComment].self, forKey: .submissionComments)
        rubricAssessment = try container.decodeIfPresent([String: CanvasRubricCriterionAssessment].self, forKey: .rubricAssessment)
        
        grade = try container.decodeIfPresent(String.self, forKey: .grade)
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        workflowState = try container.decode(String.self, forKey: .workflowState)
        
        if let submittedAtString = try? container.decodeIfPresent(String.self, forKey: .submittedAt), let date = ISO8601DateFormatter().date(from: submittedAtString) {
            submittedAt = date
        } else {
            submittedAt = try container.decodeIfPresent(Date.self, forKey: .submittedAt)
        }
    }
}

struct CanvasSubmissionComment: Codable, Identifiable {
    let id: String
    let authorId: String?
    let authorName: String?
    let authorAvatarUrl: String?
    let comment: String
    let createdAt: Date?
    let editedAt: Date?
    let attachments: [CanvasFile]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case authorName = "author_name"
        case authorAvatarUrl = "author_avatar_url"
        case comment
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case attachments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        if let authorIdValue = try? container.decodeIfPresent(AnyCodableValue.self, forKey: .authorId) {
            authorId = authorIdValue.stringValue
        } else {
            authorId = nil
        }
        
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorAvatarUrl = try container.decodeIfPresent(String.self, forKey: .authorAvatarUrl)
        comment = try container.decode(String.self, forKey: .comment)
        attachments = try container.decodeIfPresent([CanvasFile].self, forKey: .attachments)
        
        if let createdAtString = try? container.decodeIfPresent(String.self, forKey: .createdAt), let date = ISO8601DateFormatter().date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        }
        
        if let editedAtString = try? container.decodeIfPresent(String.self, forKey: .editedAt), let date = ISO8601DateFormatter().date(from: editedAtString) {
            editedAt = date
        } else {
            editedAt = try container.decodeIfPresent(Date.self, forKey: .editedAt)
        }
    }
}

struct CanvasRubricCriterionAssessment: Codable {
    let points: Double?
    let comments: String?
    let ratingId: String?
    
    enum CodingKeys: String, CodingKey {
        case points
        case comments
        case ratingId = "rating_id"
    }
}


struct CanvasRubricCriterion: Codable, Identifiable {
    let id: String
    let description: String
    let longDescription: String?
    let points: Double
    let ratings: [CanvasRubricRating]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case longDescription = "long_description"
        case points
        case ratings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idValue = try container.decode(AnyCodableValue.self, forKey: .id)
        id = idValue.stringValue
        
        description = try container.decode(String.self, forKey: .description)
        longDescription = try container.decodeIfPresent(String.self, forKey: .longDescription)
        points = try container.decode(Double.self, forKey: .points)
        ratings = try container.decodeIfPresent([CanvasRubricRating].self, forKey: .ratings)
    }
}

struct CanvasRubricRating: Codable, Identifiable {
    let id: String
    let description: String
    let longDescription: String?
    let points: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case longDescription = "long_description"
        case points
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idValue = try container.decode(AnyCodableValue.self, forKey: .id)
        id = idValue.stringValue
        
        description = try container.decode(String.self, forKey: .description)
        longDescription = try container.decodeIfPresent(String.self, forKey: .longDescription)
        points = try container.decode(Double.self, forKey: .points)
    }
}

