//
//  CourseAssignmentsView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CourseAssignmentsView: View {
    let course: CanvasCourse
    let session: LoginSession
    
    @State private var assignments: [CanvasAssignment] = []
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
                            await loadAssignments()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if assignments.isEmpty {
                VStack(spacing: 16) {
                    Text("No Assignments")
                        .font(.headline)
                    Text("There are no assignments in this course.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(assignments) { assignment in
                        AssignmentRow(assignment: assignment, session: session, courseId: course.id)
                    }
                }
            }
        }
        .task {
            await loadAssignments()
        }
        .refreshable {
            await loadAssignments()
        }
    }
    
    private func loadAssignments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            assignments = try await apiService.getAssignments(courseId: course.id)
        } catch {
            errorMessage = "Failed to load assignments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AssignmentRow: View {
    let assignment: CanvasAssignment
    let session: LoginSession
    let courseId: String
    
    var body: some View {
        NavigationLink {
            AssignmentDetailView(assignment: assignment, courseId: courseId, session: session)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let dueAt = assignment.dueAt {
                        Text(formatDate(dueAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let pointsPossible = assignment.pointsPossible {
                        Text("\(Int(pointsPossible)) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let submission = assignment.submission {
                        if let grade = submission.grade {
                            Text("Grade: \(grade)")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if submission.workflowState == "submitted" {
                            Text("Submitted")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if assignment.lockedForUser == true, let explanation = assignment.lockExplanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .opacity(assignment.lockedForUser == true ? 0.6 : 1.0)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

