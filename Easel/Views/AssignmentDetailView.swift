//
//  AssignmentDetailView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import WebKit

struct AssignmentDetailView: View {
    let assignment: CanvasAssignment
    let courseId: String
    let session: LoginSession
    
    @State private var fullAssignment: CanvasAssignment?
    @State private var submission: CanvasSubmission?
    @State private var isLoading = false
    @State private var isLoadingSubmission = false
    @State private var errorMessage: String?
    @State private var selectedTab: AssignmentTab = .details
    
    enum AssignmentTab: String, CaseIterable {
        case details = "Details"
        case submission = "Submission"
        case comments = "Comments"
        case rubric = "Rubric"
        
        static var availableTabs: [AssignmentTab] {
            return allCases
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                let assignment = fullAssignment ?? self.assignment
                let hasSubmission = submission != nil || assignment.submission != nil
                let hasRubric = (fullAssignment?.rubric ?? assignment.rubric) != nil && !(fullAssignment?.rubric ?? assignment.rubric ?? []).isEmpty
                
                if hasSubmission || hasRubric {
                    Picker("Assignment Tab", selection: $selectedTab) {
                        ForEach(AssignmentTab.allCases.filter { tab in
                            switch tab {
                            case .details: return true
                            case .submission, .comments: return hasSubmission
                            case .rubric: return hasRubric
                            }
                        }, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                
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
                                        await loadAssignment()
                                    }
                                }
                            }
                            .padding()
                        } else {
                            let assignment = fullAssignment ?? self.assignment
                            
                            switch selectedTab {
                            case .details:
                                detailsView(assignment: assignment)
                            case .submission:
                                submissionView(assignment: assignment)
                            case .comments:
                                commentsView()
                            case .rubric:
                                rubricView(assignment: assignment)
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .navigationTitle(assignment.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAssignment()
        }
    }
    
    @ViewBuilder
    private func headerSection(assignment: CanvasAssignment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let points = assignment.pointsPossible {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("\(Int(points)) points")
                        .font(.headline)
                }
            }
            
            if let dueAt = assignment.dueAt {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Due: \(formatDate(dueAt))")
                        .font(.subheadline)
                }
            }
            
            if let submission = assignment.submission {
                HStack {
                    Image(systemName: submission.workflowState == "submitted" ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(submission.workflowState == "submitted" ? .green : .gray)
                    if let grade = submission.grade {
                        Text("Grade: \(grade)")
                            .font(.subheadline)
                    } else if submission.workflowState == "submitted" {
                        Text("Submitted")
                            .font(.subheadline)
                    } else {
                        Text("Not submitted")
                            .font(.subheadline)
                    }
                }
            }
            
            if !assignment.submissionTypes.isEmpty {
                HStack {
                    Image(systemName: "paperclip")
                        .foregroundColor(.gray)
                    Text("Submission types: \(assignment.submissionTypes.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func descriptionSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            
            WebView(htmlString: description, baseURL: session.baseURL, session: session)
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func lockedSection(explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Locked")
                    .font(.headline)
            }
            Text(explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func detailsView(assignment: CanvasAssignment) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection(assignment: assignment)
            
            if let description = assignment.description, !description.isEmpty {
                Divider()
                descriptionSection(description: description)
            }
            
            if assignment.lockedForUser == true, let explanation = assignment.lockExplanation {
                Divider()
                lockedSection(explanation: explanation)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func submissionView(assignment: CanvasAssignment) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoadingSubmission {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let submission = submission {
                if let body = submission.body, !body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Submission Content")
                            .font(.headline)
                        WebView(htmlString: body, baseURL: session.baseURL, session: session)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                if let attachments = submission.attachments, !attachments.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Submission Files")
                            .font(.headline)
                        ForEach(attachments, id: \.id) { file in
                            SubmissionFileRow(file: file, baseURL: session.baseURL, session: session)
                        }
                    }
                }
                
                if submission.body == nil && (submission.attachments?.isEmpty ?? true) {
                    Text("No submission content available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                Text("No submission found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .task {
            if submission == nil {
                await loadSubmission()
            }
        }
    }
    
    @ViewBuilder
    private func commentsView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let comments = submission?.submissionComments, !comments.isEmpty {
                ForEach(comments) { comment in
                    SubmissionCommentRow(comment: comment, baseURL: session.baseURL, session: session)
                }
            } else {
                Text("No comments available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .task {
            if submission == nil {
                await loadSubmission()
            }
        }
    }
    
    @ViewBuilder
    private func rubricView(assignment: CanvasAssignment) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoadingSubmission {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let rubric = fullAssignment?.rubric ?? assignment.rubric, !rubric.isEmpty {
                ForEach(rubric) { criterion in
                    RubricCriterionView(
                        criterion: criterion,
                        assessment: submission?.rubricAssessment?[criterion.id],
                        baseURL: session.baseURL,
                        session: session
                    )
                }
            } else {
                Text("No rubric available for this assignment")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .task {
            if submission == nil {
                await loadSubmission()
            }
        }
    }
    
    private func loadAssignment() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            fullAssignment = try await apiService.getAssignment(courseId: courseId, assignmentId: assignment.id)
        } catch {
            errorMessage = "Failed to load assignment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadSubmission() async {
        isLoadingSubmission = true
        
        do {
            let apiService = CanvasAPIService(session: session)
            submission = try await apiService.getSubmission(courseId: courseId, assignmentId: assignment.id)
        } catch {
            print("Failed to load submission: \(error.localizedDescription)")
        }
        
        isLoadingSubmission = false
    }
    
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SubmissionFileRow: View {
    let file: CanvasFile
    let baseURL: URL
    let session: LoginSession
    
    var body: some View {
        HStack {
            Image(systemName: fileIcon(for: file.mimeClass))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayName)
                    .font(.body)
                
                if let size = file.size {
                    Text(formatFileSize(size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let url = file.url {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func fileIcon(for mimeClass: String) -> String {
        switch mimeClass {
        case "image": return "photo"
        case "video": return "video"
        case "audio": return "music.note"
        case "pdf": return "doc.text"
        case "text": return "doc.text"
        default: return "doc"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SubmissionCommentRow: View {
    let comment: CanvasSubmissionComment
    let baseURL: URL
    let session: LoginSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if let avatarUrl = comment.authorAvatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.gradient)
                            .overlay {
                                Text((comment.authorName ?? "?").prefix(1).uppercased())
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Text((comment.authorName ?? "?").prefix(1).uppercased())
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.authorName ?? "Unknown")
                        .font(.headline)
                    
                    if let createdAt = comment.createdAt {
                        Text(formatDate(createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            WebView(htmlString: comment.comment, baseURL: baseURL, session: session)
                .frame(maxWidth: .infinity)
            
            if let attachments = comment.attachments, !attachments.isEmpty {
                ForEach(attachments, id: \.id) { file in
                    SubmissionFileRow(file: file, baseURL: baseURL, session: session)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RubricCriterionView: View {
    let criterion: CanvasRubricCriterion
    let assessment: CanvasRubricCriterionAssessment?
    let baseURL: URL
    let session: LoginSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(criterion.description)
                        .font(.headline)
                    
                    if let longDescription = criterion.longDescription {
                        Text(longDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(criterion.points)) pts")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            if let assessment = assessment {
                Divider()
                
                if let points = assessment.points {
                    HStack {
                        Text("Points Awarded:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(points, specifier: "%.1f") / \(Int(criterion.points))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                if let comments = assessment.comments, !comments.isEmpty {
                    WebView(htmlString: comments, baseURL: baseURL, session: session)
                        .frame(maxWidth: .infinity)
                }
            }
            
            if let ratings = criterion.ratings, !ratings.isEmpty {
                Divider()
                Text("Rating Scale:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(ratings) { rating in
                    HStack {
                        Text(rating.description)
                            .font(.caption)
                        Spacer()
                        Text("\(rating.points, specifier: "%.1f") pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

