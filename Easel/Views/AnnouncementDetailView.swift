//
//  AnnouncementDetailView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import WebKit

struct AnnouncementDetailView: View {
    let announcement: CanvasDiscussionTopic
    let courseId: String
    let session: LoginSession
    
    @State private var fullAnnouncement: CanvasDiscussionTopic?
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
                                    await loadAnnouncement()
                                }
                            }
                        }
                        .padding()
                    } else {
                        let announcement = fullAnnouncement ?? self.announcement
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection(announcement: announcement)
                            
                            if let message = announcement.message, !message.isEmpty {
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
        .navigationTitle(announcement.title ?? "Announcement")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAnnouncement()
        }
    }
    
    @ViewBuilder
    private func headerSection(announcement: CanvasDiscussionTopic) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let author = announcement.author, let displayName = author.displayName {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Posted by \(displayName)")
                        .font(.subheadline)
                }
            }
            
            if let postedAt = announcement.postedAt {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Posted: \(formatDate(postedAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if announcement.discussionSubentryCount > 0 {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(.blue)
                    Text("\(announcement.discussionSubentryCount) \(announcement.discussionSubentryCount == 1 ? "reply" : "replies")")
                        .font(.subheadline)
                }
            }
            
            if announcement.pinned == true {
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
    
    private func loadAnnouncement() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            fullAnnouncement = try await apiService.getDiscussionTopic(courseId: courseId, topicId: announcement.id)
        } catch {
            errorMessage = "Failed to load announcement: \(error.localizedDescription)"
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

