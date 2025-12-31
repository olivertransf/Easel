//
//  CanvasDiscussionTopic.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

struct CanvasDiscussionTopic: Codable, Identifiable {
    struct Author: Codable {
        let id: String?
        let displayName: String?
        let avatarImageUrl: URL?
        
        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case avatarImageUrl = "avatar_image_url"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let intId = try? container.decodeIfPresent(Int.self, forKey: .id) {
                id = String(intId)
            } else if let stringId = try? container.decodeIfPresent(String.self, forKey: .id) {
                id = stringId
            } else {
                id = nil
            }
            
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            avatarImageUrl = try container.decodeIfPresent(URL.self, forKey: .avatarImageUrl)
        }
    }
    
    let id: String
    let title: String?
    let message: String?
    let htmlUrl: URL?
    let postedAt: Date?
    let lastReplyAt: Date?
    let author: Author?
    let discussionSubentryCount: Int
    let pinned: Bool?
    let locked: Bool?
    let lockedForUser: Bool
    let unreadCount: Int?
    let published: Bool
    let subscriptionHold: String?
    let allowRating: Bool
    let sortByRating: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case htmlUrl = "html_url"
        case postedAt = "posted_at"
        case lastReplyAt = "last_reply_at"
        case author
        case discussionSubentryCount = "discussion_subentry_count"
        case pinned
        case locked
        case lockedForUser = "locked_for_user"
        case unreadCount = "unread_count"
        case published
        case subscriptionHold = "subscription_hold"
        case allowRating = "allow_rating"
        case sortByRating = "sort_by_rating"
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
        author = try container.decodeIfPresent(Author.self, forKey: .author)
        discussionSubentryCount = try container.decode(Int.self, forKey: .discussionSubentryCount)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        lockedForUser = try container.decode(Bool.self, forKey: .lockedForUser)
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount)
        published = try container.decode(Bool.self, forKey: .published)
        subscriptionHold = try container.decodeIfPresent(String.self, forKey: .subscriptionHold)
        allowRating = try container.decode(Bool.self, forKey: .allowRating)
        sortByRating = try container.decode(Bool.self, forKey: .sortByRating)
        
        if let postedAtString = try? container.decodeIfPresent(String.self, forKey: .postedAt), let date = ISO8601DateFormatter().date(from: postedAtString) {
            postedAt = date
        } else {
            postedAt = try container.decodeIfPresent(Date.self, forKey: .postedAt)
        }
        
        if let lastReplyAtString = try? container.decodeIfPresent(String.self, forKey: .lastReplyAt), let date = ISO8601DateFormatter().date(from: lastReplyAtString) {
            lastReplyAt = date
        } else {
            lastReplyAt = try container.decodeIfPresent(Date.self, forKey: .lastReplyAt)
        }
    }
}

