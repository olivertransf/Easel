//
//  NotificationsView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct NotificationsView: View {
    let session: LoginSession
    @State private var activities: [CanvasActivity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var courses: [CanvasCourse] = []
    
    var body: some View {
        NavigationStack {
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
                                await loadActivities()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if activities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Notifications")
                            .font(.headline)
                        Text("You're all caught up!")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(activities) { activity in
                            ActivityRow(activity: activity, session: session, courses: courses)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadActivities()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadActivities()
            }
            .refreshable {
                await loadActivities()
            }
        }
    }
    
    private func loadActivities() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            activities = try await apiService.getActivities()
            
            let courseIds = Set(activities.compactMap { $0.courseId })
            courses = try await apiService.getCourses()
            courses = courses.filter { courseIds.contains($0.id) }
        } catch {
            errorMessage = "Failed to load notifications: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ActivityRow: View {
    let activity: CanvasActivity
    let session: LoginSession
    let courses: [CanvasCourse]
    
    var course: CanvasCourse? {
        guard let courseId = activity.courseId else { return nil }
        return courses.first { $0.id == courseId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                activityIcon
                    .font(.system(size: 20))
                    .foregroundColor(activityColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let title = activity.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    if let message = activity.message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    } else if let latestMessage = activity.latestMessages?.last {
                        Text(latestMessage.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    
                    HStack(spacing: 12) {
                        if let course = course {
                            Text(course.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(relativeTimeString(from: activity.displayDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let grade = activity.grade {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text(grade)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        } else if let score = activity.score {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text(String(format: "%.1f", score))
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .opacity(activity.readState == true ? 0.6 : 1.0)
    }
    
    private var activityIcon: Image {
        switch activity.type {
        case .submission:
            return Image(systemName: "paperplane.fill")
        case .discussion, .discussionEntry:
            return Image(systemName: "bubble.left.and.bubble.right.fill")
        case .announcement:
            return Image(systemName: "megaphone.fill")
        case .message, .conversation:
            return Image(systemName: "envelope.fill")
        case .conference:
            return Image(systemName: "video.fill")
        case .collaboration:
            return Image(systemName: "person.2.fill")
        case .assessmentRequest:
            return Image(systemName: "checkmark.circle.fill")
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .submission:
            return .green
        case .discussion, .discussionEntry:
            return .blue
        case .announcement:
            return .orange
        case .message, .conversation:
            return .purple
        case .conference:
            return .red
        case .collaboration:
            return .cyan
        case .assessmentRequest:
            return .yellow
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

