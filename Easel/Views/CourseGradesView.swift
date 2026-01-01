//
//  CourseGradesView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CourseGradesView: View {
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
                            await loadGrades()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if assignments.isEmpty {
                VStack(spacing: 16) {
                    Text("No Grades")
                        .font(.headline)
                    Text("There are no graded assignments in this course.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(assignments) { assignment in
                        GradeRow(assignment: assignment, session: session, courseId: course.id)
                    }
                }
            }
        }
        .task {
            await loadGrades()
        }
        .refreshable {
            await loadGrades()
        }
    }
    
    private func loadGrades() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            assignments = try await apiService.getGrades(courseId: course.id)
        } catch {
            errorMessage = "Failed to load grades: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct GradeRow: View {
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
                    
                    if let pointsPossible = assignment.pointsPossible {
                        Text("\(Int(pointsPossible)) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let submission = assignment.submission {
                        if let grade = submission.grade, let score = submission.score, let pointsPossible = assignment.pointsPossible {
                            Text("Grade: \(grade) (\(Int(score))/\(Int(pointsPossible)))")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if let grade = submission.grade {
                            Text("Grade: \(grade)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Not graded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dueAt = assignment.dueAt {
                        Text("Due: \(formatDate(dueAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
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

