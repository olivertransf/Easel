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
                                    await loadAssignment()
                                }
                            }
                        }
                        .padding()
                    } else {
                        let assignment = fullAssignment ?? self.assignment
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
                }
                .frame(minHeight: geometry.size.height)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

