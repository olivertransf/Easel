//
//  CanvasAssignment.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasAssignment: Codable, Identifiable {
    struct Submission: Codable {
        let submittedAt: Date?
        let grade: String?
        let score: Double?
        let workflowState: String?
        
        enum CodingKeys: String, CodingKey {
            case submittedAt = "submitted_at"
            case grade
            case score
            case workflowState = "workflow_state"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            grade = try container.decodeIfPresent(String.self, forKey: .grade)
            score = try container.decodeIfPresent(Double.self, forKey: .score)
            workflowState = try container.decodeIfPresent(String.self, forKey: .workflowState)
            
            if let submittedAtString = try? container.decodeIfPresent(String.self, forKey: .submittedAt), let date = ISO8601DateFormatter().date(from: submittedAtString) {
                submittedAt = date
            } else {
                submittedAt = try container.decodeIfPresent(Date.self, forKey: .submittedAt)
            }
        }
    }
    
    let id: String
    let name: String
    let description: String?
    let htmlUrl: URL
    let dueAt: Date?
    let pointsPossible: Double?
    let lockedForUser: Bool?
    let lockExplanation: String?
    let submissionTypes: [String]
    let published: Bool?
    let submission: Submission?
    let rubric: [CanvasRubricCriterion]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case htmlUrl = "html_url"
        case dueAt = "due_at"
        case pointsPossible = "points_possible"
        case lockedForUser = "locked_for_user"
        case lockExplanation = "lock_explanation"
        case submissionTypes = "submission_types"
        case published
        case submission
        case rubric
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        htmlUrl = try container.decode(URL.self, forKey: .htmlUrl)
        pointsPossible = try container.decodeIfPresent(Double.self, forKey: .pointsPossible)
        lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
        lockExplanation = try container.decodeIfPresent(String.self, forKey: .lockExplanation)
        submissionTypes = try container.decodeIfPresent([String].self, forKey: .submissionTypes) ?? []
        published = try container.decodeIfPresent(Bool.self, forKey: .published)
        
        submission = try container.decodeIfPresent(Submission.self, forKey: .submission)
        rubric = try container.decodeIfPresent([CanvasRubricCriterion].self, forKey: .rubric)
        
        if let dueAtString = try? container.decodeIfPresent(String.self, forKey: .dueAt), let date = ISO8601DateFormatter().date(from: dueAtString) {
            dueAt = date
        } else {
            dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        }
    }
}

