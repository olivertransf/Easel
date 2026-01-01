//
//  CalendarView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CalendarViewRepresentable: UIViewRepresentable {
    @Binding var selectedDate: Date
    let assignmentsByDate: [String: [AssignmentWithCourse]]
    let dateFormatter: DateFormatter
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.fontDesign = .rounded
        calendarView.delegate = context.coordinator
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        
        var dateComponents = Set<DateComponents>()
        for (dateKey, assignments) in assignmentsByDate where !assignments.isEmpty {
            if let date = dateFormatter.date(from: dateKey) {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                dateComponents.insert(components)
            }
        }
        
        calendarView.reloadDecorations(forDateComponents: Array(dateComponents), animated: false)
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        if context.coordinator.selectedDate != selectedDate {
            context.coordinator.selectedDate = selectedDate
        }
        
        var dateComponents = Set<DateComponents>()
        for (dateKey, assignments) in assignmentsByDate where !assignments.isEmpty {
            if let date = dateFormatter.date(from: dateKey) {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                dateComponents.insert(components)
            }
        }
        
        let componentsArray = Array(dateComponents)
        if !componentsArray.isEmpty {
            uiView.reloadDecorations(forDateComponents: componentsArray, animated: false)
        }
        
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            if selection.selectedDate != components {
                selection.setSelected(components, animated: false)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewRepresentable
        
        var selectedDate: Date {
            didSet {
                parent.selectedDate = selectedDate
            }
        }
        
        init(_ parent: CalendarViewRepresentable) {
            self.parent = parent
            self.selectedDate = parent.selectedDate
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            if let dateComponents = dateComponents, let date = Calendar.current.date(from: dateComponents) {
                DispatchQueue.main.async {
                    self.selectedDate = date
                    self.parent.selectedDate = date
                }
            }
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let dateKey = parent.dateFormatter.string(from: Calendar.current.date(from: dateComponents) ?? Date())
            if let assignments = parent.assignmentsByDate[dateKey], !assignments.isEmpty {
                return .default(color: .systemBlue, size: .small)
            }
            return nil
        }
    }
}

struct CalendarView: View {
    let session: LoginSession
    @State private var assignmentsByDate: [String: [AssignmentWithCourse]] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDate: Date = Date()
    @State private var courses: [CanvasCourse] = []
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
                                await loadAssignments()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        splitView
                    } else {
                        compactView
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadAssignments()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
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
    }
    
    private var splitView: some View {
        HStack(spacing: 0) {
            VStack {
                CalendarViewRepresentable(selectedDate: $selectedDate, assignmentsByDate: assignmentsByDate, dateFormatter: dateFormatter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 400)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            selectedDateAssignments
                .frame(maxWidth: .infinity)
        }
    }
    
    private var compactView: some View {
        VStack(spacing: 0) {
            CalendarViewRepresentable(selectedDate: $selectedDate, assignmentsByDate: assignmentsByDate, dateFormatter: dateFormatter)
                .frame(height: 400)
            
            Divider()
            
            selectedDateAssignments
        }
    }
    
    
    private var selectedDateAssignments: some View {
        let dateKey = dateFormatter.string(from: selectedDate)
        let assignments = assignmentsByDate[dateKey] ?? []
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dateString(from: selectedDate))
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                if !assignments.isEmpty {
                    Text("\(assignments.count) assignment\(assignments.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.trailing)
                }
            }
            
            if assignments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("No assignments due")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(assignments) { item in
                        CalendarAssignmentRow(assignment: item.assignment, course: item.course, session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func loadAssignments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            
            courses = try await apiService.getCourses()
            
            var assignmentsByDateDict: [String: [AssignmentWithCourse]] = [:]
            
            for course in courses {
                do {
                    let assignments = try await apiService.getAssignments(courseId: course.id)
                    for assignment in assignments {
                        if let dueAt = assignment.dueAt {
                            let dateKey = dateFormatter.string(from: dueAt)
                            if assignmentsByDateDict[dateKey] == nil {
                                assignmentsByDateDict[dateKey] = []
                            }
                            assignmentsByDateDict[dateKey]?.append(AssignmentWithCourse(
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
            
            for (key, value) in assignmentsByDateDict {
                assignmentsByDateDict[key] = value.sorted { assignment1, assignment2 in
                    guard let due1 = assignment1.assignment.dueAt,
                          let due2 = assignment2.assignment.dueAt else {
                        return false
                    }
                    return due1 < due2
                }
            }
            
            assignmentsByDate = assignmentsByDateDict
        } catch {
            errorMessage = "Failed to load assignments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct CalendarAssignmentRow: View {
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
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(timeString(from: dueAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
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
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

