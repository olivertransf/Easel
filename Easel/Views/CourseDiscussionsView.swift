//
//  CourseDiscussionsView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CourseDiscussionsView: View {
    let course: CanvasCourse
    let session: LoginSession
    
    @State private var discussions: [CanvasDiscussionTopic] = []
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
                            await loadDiscussions()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if discussions.isEmpty {
                VStack(spacing: 16) {
                    Text("No Discussions")
                        .font(.headline)
                    Text("There are no discussions in this course.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(discussions) { discussion in
                        DiscussionRow(discussion: discussion, session: session, courseId: course.id)
                    }
                }
            }
        }
        .task {
            await loadDiscussions()
        }
        .refreshable {
            await loadDiscussions()
        }
    }
    
    private func loadDiscussions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            discussions = try await apiService.getDiscussions(courseId: course.id)
        } catch let error as APIError {
            if case .httpError(let code) = error, code == 403 || code == 404 {
                errorMessage = "Discussions are not available for this course."
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = "Failed to load discussions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct DiscussionRow: View {
    let discussion: CanvasDiscussionTopic
    let session: LoginSession
    let courseId: String
    
    var body: some View {
        NavigationLink {
            DiscussionDetailView(discussion: discussion, courseId: courseId, session: session)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if discussion.pinned == true {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(discussion.title ?? "Untitled")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let author = discussion.author {
                        Text(author.displayName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let postedAt = discussion.postedAt {
                        Text(formatDate(postedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if discussion.discussionSubentryCount > 0 {
                        Text("\(discussion.discussionSubentryCount) \(discussion.discussionSubentryCount == 1 ? "reply" : "replies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if discussion.unreadCount ?? 0 > 0 {
                        Text("\(discussion.unreadCount!) unread")
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

