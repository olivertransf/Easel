//
//  CourseAnnouncementsView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CourseAnnouncementsView: View {
    let course: CanvasCourse
    let session: LoginSession
    
    @State private var announcements: [CanvasDiscussionTopic] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadAnnouncements()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if announcements.isEmpty {
                VStack(spacing: 16) {
                    Text("No Announcements")
                        .font(.headline)
                    Text("There are no announcements in this course.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(announcements) { announcement in
                        AnnouncementRow(announcement: announcement, session: session, courseId: course.id)
                    }
                }
            }
        }
        .task {
            await loadAnnouncements()
        }
        .refreshable {
            await loadAnnouncements()
        }
    }
    
    private func loadAnnouncements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            announcements = try await apiService.getAnnouncements(courseId: course.id)
        } catch {
            errorMessage = "Failed to load announcements: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AnnouncementRow: View {
    let announcement: CanvasDiscussionTopic
    let session: LoginSession
    let courseId: String
    
    var body: some View {
        NavigationLink {
            AnnouncementDetailView(announcement: announcement, courseId: courseId, session: session)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if announcement.pinned == true {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
                
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title ?? "Untitled")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let author = announcement.author {
                        Text(author.displayName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let postedAt = announcement.postedAt {
                        Text(formatDate(postedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if announcement.discussionSubentryCount > 0 {
                        Text("\(announcement.discussionSubentryCount) \(announcement.discussionSubentryCount == 1 ? "reply" : "replies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if announcement.unreadCount ?? 0 > 0 {
                        Text("\(announcement.unreadCount!) unread")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

