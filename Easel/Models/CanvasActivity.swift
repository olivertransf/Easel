//
//  CanvasActivity.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

enum ActivityType: String, Codable {
    case discussion = "DiscussionTopic"
    case discussionEntry = "DiscussionEntry"
    case announcement = "Announcement"
    case conversation = "Conversation"
    case message = "Message"
    case submission = "Submission"
    case conference = "WebConference"
    case collaboration = "Collaboration"
    case assessmentRequest = "AssessmentRequest"
}

struct CanvasActivity: Codable, Identifiable {
    let id: String
    let title: String?
    let message: String?
    let htmlUrl: URL?
    let createdAt: Date
    let updatedAt: Date
    let type: ActivityType
    let contextType: String?
    let courseId: String?
    let groupId: String?
    let score: Double?
    let grade: String?
    let readState: Bool?
    let notificationCategory: String?
    let latestMessages: [ActivityMessage]?
    let announcementId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case type
        case contextType = "context_type"
        case courseId = "course_id"
        case groupId = "group_id"
        case score
        case grade
        case readState = "read_state"
        case notificationCategory = "notification_category"
        case latestMessages = "latest_messages"
        case announcementId = "announcement_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        htmlUrl = try container.decodeIfPresent(URL.self, forKey: .htmlUrl)
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: createdAtString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format: \(createdAtString)")
            }
        }
        
        if let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: updatedAtString) {
                updatedAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Invalid date format: \(updatedAtString)")
            }
        }
        
        type = try container.decode(ActivityType.self, forKey: .type)
        contextType = try container.decodeIfPresent(String.self, forKey: .contextType)
        
        if let intCourseId = try? container.decodeIfPresent(Int.self, forKey: .courseId) {
            courseId = String(intCourseId)
        } else {
            courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        }
        
        if let intGroupId = try? container.decodeIfPresent(Int.self, forKey: .groupId) {
            groupId = String(intGroupId)
        } else {
            groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        }
        
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        grade = try container.decodeIfPresent(String.self, forKey: .grade)
        readState = try container.decodeIfPresent(Bool.self, forKey: .readState)
        notificationCategory = try container.decodeIfPresent(String.self, forKey: .notificationCategory)
        latestMessages = try container.decodeIfPresent([ActivityMessage].self, forKey: .latestMessages)
        
        if let intAnnouncementId = try? container.decodeIfPresent(Int.self, forKey: .announcementId) {
            announcementId = String(intAnnouncementId)
        } else {
            announcementId = try container.decodeIfPresent(String.self, forKey: .announcementId)
        }
    }
    
    var displayDate: Date {
        latestMessages?.max(by: { $0.createdAt < $1.createdAt })?.createdAt ?? updatedAt
    }
}

struct ActivityMessage: Codable {
    let id: String
    let createdAt: Date
    let body: String?
    let authorId: String
    let message: String
    let participatingUserIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case body
        case authorId = "author_id"
        case message
        case participatingUserIds = "participating_user_ids"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: createdAtString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format: \(createdAtString)")
            }
        }
        
        body = try container.decodeIfPresent(String.self, forKey: .body)
        
        if let intAuthorId = try? container.decodeIfPresent(Int.self, forKey: .authorId) {
            authorId = String(intAuthorId)
        } else {
            authorId = try container.decode(String.self, forKey: .authorId)
        }
        
        message = try container.decode(String.self, forKey: .message)
        
        if let userIds = try? container.decodeIfPresent([Int].self, forKey: .participatingUserIds) {
            participatingUserIds = userIds.map { String($0) }
        } else {
            participatingUserIds = try container.decodeIfPresent([String].self, forKey: .participatingUserIds) ?? []
        }
    }
}

