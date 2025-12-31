//
//  CanvasModule.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasModule: Codable, Identifiable {
    let id: String
    let name: String
    let position: Int
    let published: Bool?
    let prerequisiteModuleIds: [String]
    let requireSequentialProgress: Bool?
    let state: String?
    var items: [CanvasModuleItem]?
    let unlockAt: Date?
    let estimatedDuration: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case position
        case published
        case prerequisiteModuleIds = "prerequisite_module_ids"
        case requireSequentialProgress = "require_sequential_progress"
        case state
        case items
        case unlockAt = "unlock_at"
        case estimatedDuration = "estimated_duration"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        position = try container.decode(Int.self, forKey: .position)
        published = try container.decodeIfPresent(Bool.self, forKey: .published)
        prerequisiteModuleIds = try container.decodeIfPresent([String].self, forKey: .prerequisiteModuleIds) ?? []
        requireSequentialProgress = try container.decodeIfPresent(Bool.self, forKey: .requireSequentialProgress)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        items = try container.decodeIfPresent([CanvasModuleItem].self, forKey: .items)
        
        if let unlockAtString = try? container.decodeIfPresent(String.self, forKey: .unlockAt), let date = ISO8601DateFormatter().date(from: unlockAtString) {
            unlockAt = date
        } else {
            unlockAt = try container.decodeIfPresent(Date.self, forKey: .unlockAt)
        }
        
        estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
    }
}

struct CanvasModuleItem: Codable, Identifiable {
    struct ContentDetails: Codable {
        let dueAt: Date?
        let pointsPossible: Double?
        let lockedForUser: Bool?
        let lockExplanation: String?
        let hidden: Bool?
        let unlockAt: Date?
        let lockAt: Date?
        let pageUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case dueAt = "due_at"
            case pointsPossible = "points_possible"
            case lockedForUser = "locked_for_user"
            case lockExplanation = "lock_explanation"
            case hidden
            case unlockAt = "unlock_at"
            case lockAt = "lock_at"
            case pageUrl = "page_url"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            pointsPossible = try container.decodeIfPresent(Double.self, forKey: .pointsPossible)
            lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
            lockExplanation = try container.decodeIfPresent(String.self, forKey: .lockExplanation)
            hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
            pageUrl = try container.decodeIfPresent(String.self, forKey: .pageUrl)
            
            if let dueAtString = try? container.decodeIfPresent(String.self, forKey: .dueAt), let date = ISO8601DateFormatter().date(from: dueAtString) {
                dueAt = date
            } else {
                dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
            }
            
            if let unlockAtString = try? container.decodeIfPresent(String.self, forKey: .unlockAt), let date = ISO8601DateFormatter().date(from: unlockAtString) {
                unlockAt = date
            } else {
                unlockAt = try container.decodeIfPresent(Date.self, forKey: .unlockAt)
            }
            
            if let lockAtString = try? container.decodeIfPresent(String.self, forKey: .lockAt), let date = ISO8601DateFormatter().date(from: lockAtString) {
                lockAt = date
            } else {
                lockAt = try container.decodeIfPresent(Date.self, forKey: .lockAt)
            }
        }
    }
    
    let id: String
    let moduleId: String
    let position: Int
    let title: String
    let indent: Int
    let type: String?
    let contentId: String?
    let htmlUrl: URL?
    let url: URL?
    let pageId: String?
    let published: Bool?
    let unpublishable: Bool?
    let contentDetails: ContentDetails?
    let completionRequirement: CompletionRequirement?
    let estimatedDuration: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case moduleId = "module_id"
        case position
        case title
        case indent
        case type
        case contentId = "content_id"
        case htmlUrl = "html_url"
        case url
        case pageId = "page_url"
        case published
        case unpublishable
        case contentDetails = "content_details"
        case completionRequirement = "completion_requirement"
        case estimatedDuration = "estimated_duration"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        if let intModuleId = try? container.decode(Int.self, forKey: .moduleId) {
            moduleId = String(intModuleId)
        } else {
            moduleId = try container.decode(String.self, forKey: .moduleId)
        }
        
        position = try container.decode(Int.self, forKey: .position)
        title = try container.decode(String.self, forKey: .title)
        indent = try container.decodeIfPresent(Int.self, forKey: .indent) ?? 0
        type = try container.decodeIfPresent(String.self, forKey: .type)
        
        if let intContentId = try? container.decode(Int.self, forKey: .contentId) {
            contentId = String(intContentId)
        } else {
            contentId = try container.decodeIfPresent(String.self, forKey: .contentId)
        }
        
        htmlUrl = try container.decodeIfPresent(URL.self, forKey: .htmlUrl)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        pageId = try container.decodeIfPresent(String.self, forKey: .pageId)
        published = try container.decodeIfPresent(Bool.self, forKey: .published)
        unpublishable = try container.decodeIfPresent(Bool.self, forKey: .unpublishable)
        contentDetails = try container.decodeIfPresent(ContentDetails.self, forKey: .contentDetails)
        completionRequirement = try container.decodeIfPresent(CompletionRequirement.self, forKey: .completionRequirement)
        estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
    }
}

struct CompletionRequirement: Codable {
    let type: String
    let minScore: Double?
    let completed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case minScore = "min_score"
        case completed
    }
}

struct CanvasPlannable: Codable, Identifiable {
    let id: String
    let courseId: String?
    let plannableType: String
    let title: String?
    let htmlUrl: URL?
    let plannableDate: Date?
    let details: String?
    let pointsPossible: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case plannableType = "plannable_type"
        case title
        case htmlUrl = "html_url"
        case plannableDate = "plannable_date"
        case details
        case pointsPossible = "points_possible"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        if let intCourseId = try? container.decode(Int.self, forKey: .courseId) {
            courseId = String(intCourseId)
        } else {
            courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        }
        
        plannableType = try container.decode(String.self, forKey: .plannableType)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        htmlUrl = try container.decodeIfPresent(URL.self, forKey: .htmlUrl)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        pointsPossible = try container.decodeIfPresent(Double.self, forKey: .pointsPossible)
        
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .plannableDate), let date = ISO8601DateFormatter().date(from: dateString) {
            plannableDate = date
        } else {
            plannableDate = try container.decodeIfPresent(Date.self, forKey: .plannableDate)
        }
    }
}

struct CanvasCalendarEvent: Codable, Identifiable {
    let id: String
    let htmlUrl: URL
    let title: String
    let startAt: Date?
    let endAt: Date?
    let allDay: Bool
    let type: String
    let contextCode: String
    let contextName: String?
    let description: String?
    let hidden: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case htmlUrl = "html_url"
        case title
        case startAt = "start_at"
        case endAt = "end_at"
        case allDay = "all_day"
        case type
        case contextCode = "context_code"
        case contextName = "context_name"
        case description
        case hidden
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        htmlUrl = try container.decode(URL.self, forKey: .htmlUrl)
        title = try container.decode(String.self, forKey: .title)
        allDay = try container.decodeIfPresent(Bool.self, forKey: .allDay) ?? false
        type = try container.decode(String.self, forKey: .type)
        contextCode = try container.decode(String.self, forKey: .contextCode)
        contextName = try container.decodeIfPresent(String.self, forKey: .contextName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        
        if let startAtString = try? container.decodeIfPresent(String.self, forKey: .startAt), let date = ISO8601DateFormatter().date(from: startAtString) {
            startAt = date
        } else {
            startAt = try container.decodeIfPresent(Date.self, forKey: .startAt)
        }
        
        if let endAtString = try? container.decodeIfPresent(String.self, forKey: .endAt), let date = ISO8601DateFormatter().date(from: endAtString) {
            endAt = date
        } else {
            endAt = try container.decodeIfPresent(Date.self, forKey: .endAt)
        }
    }
}

