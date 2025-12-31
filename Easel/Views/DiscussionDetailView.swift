//
//  DiscussionDetailView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import WebKit

struct DiscussionDetailView: View {
    let discussion: CanvasDiscussionTopic
    let courseId: String
    let session: LoginSession
    
    @State private var fullDiscussion: CanvasDiscussionTopic?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                            Button("Retry") {
                                Task {
                                    await loadDiscussion()
                                }
                            }
                        }
                        .padding()
                    } else {
                        let discussion = fullDiscussion ?? self.discussion
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection(discussion: discussion)
                            
                            if let message = discussion.message, !message.isEmpty {
                                Divider()
                                messageSection(message: message)
                            }
                        }
                        .padding()
                    }
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .navigationTitle(discussion.title ?? "Discussion")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadDiscussion()
        }
    }
    
    @ViewBuilder
    private func headerSection(discussion: CanvasDiscussionTopic) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let author = discussion.author, let displayName = author.displayName {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Posted by \(displayName)")
                        .font(.subheadline)
                }
            }
            
            if let postedAt = discussion.postedAt {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Posted: \(formatDate(postedAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let lastReplyAt = discussion.lastReplyAt {
                HStack {
                    Image(systemName: "arrow.turn.up.right")
                        .foregroundColor(.blue)
                    Text("Last reply: \(formatDate(lastReplyAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if discussion.discussionSubentryCount > 0 {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(.blue)
                    Text("\(discussion.discussionSubentryCount) \(discussion.discussionSubentryCount == 1 ? "reply" : "replies")")
                        .font(.subheadline)
                }
            }
            
            if discussion.unreadCount ?? 0 > 0 {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 8))
                    Text("\(discussion.unreadCount!) unread")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            if discussion.pinned == true {
                HStack {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                    Text("Pinned")
                        .font(.subheadline)
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.headline)
            
            WebView(htmlString: message, baseURL: session.baseURL, session: session)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func loadDiscussion() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            fullDiscussion = try await apiService.getDiscussionTopic(courseId: courseId, topicId: discussion.id)
        } catch {
            errorMessage = "Failed to load discussion: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

