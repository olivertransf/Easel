//
//  TodosView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct AssignmentWithCourse: Identifiable {
    let id: String
    let assignment: CanvasAssignment
    let course: CanvasCourse
}

struct TodosView: View {
    let session: LoginSession
    @State private var upcomingAssignments: [AssignmentWithCourse] = []
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
                                await loadTodos()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if upcomingAssignments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("All Caught Up!")
                            .font(.headline)
                        Text("No upcoming assignments")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(upcomingAssignments) { item in
                            TodoRow(assignment: item.assignment, course: item.course, session: session)
                        }
                    }
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadTodos()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadTodos()
            }
            .refreshable {
                await loadTodos()
            }
        }
    }
    
    private func loadTodos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            
            courses = try await apiService.getCourses()
            
            var allAssignments: [AssignmentWithCourse] = []
            
            for course in courses {
                do {
                    let assignments = try await apiService.getAssignments(courseId: course.id)
                    for assignment in assignments {
                        if isUpcoming(assignment: assignment) {
                            allAssignments.append(AssignmentWithCourse(
                                id: "\(course.id)-\(assignment.id)",
                                assignment: assignment,
                                course: course
                            ))
                        }
                    }
                } catch {
                    print("Failed to load assignments for course \(course.id): \(error.localizedDescription)")
                }
            }
            
            upcomingAssignments = allAssignments.sorted { assignment1, assignment2 in
                guard let due1 = assignment1.assignment.dueAt,
                      let due2 = assignment2.assignment.dueAt else {
                    return false
                }
                return due1 < due2
            }
        } catch {
            errorMessage = "Failed to load todos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func isUpcoming(assignment: CanvasAssignment) -> Bool {
        guard let dueAt = assignment.dueAt else {
            return false
        }
        
        let now = Date()
        if dueAt < now {
            return false
        }
        
        if let submission = assignment.submission,
           submission.workflowState == "submitted" || submission.workflowState == "graded" {
            return false
        }
        
        return assignment.published != false
    }
}

struct TodoRow: View {
    let assignment: CanvasAssignment
    let course: CanvasCourse
    let session: LoginSession
    
    var body: some View {
        NavigationLink {
            AssignmentDetailView(assignment: assignment, courseId: course.id, session: session)
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
                    
                    Text(course.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let dueAt = assignment.dueAt {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDueDate(dueAt))
                                .font(.caption)
                                .foregroundColor(dueDateColor(dueAt))
                        }
                    }
                    
                    if let pointsPossible = assignment.pointsPossible {
                        Text("\(Int(pointsPossible)) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Due today"
        } else if calendar.isDateInTomorrow(date) {
            return "Due tomorrow"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Due \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Due \(formatter.string(from: date))"
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return .red
        } else if calendar.isDateInTomorrow(date) {
            return .orange
        } else {
            return .secondary
        }
    }
}

