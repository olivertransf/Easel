//
//  CourseDetailView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import WebKit

struct CourseDetailView: View {
    let course: CanvasCourse
    @ObservedObject var loginService: LoginService
    let session: LoginSession
    @State private var selectedTab: CourseTab = .home
    
    enum CourseTab: String, CaseIterable {
        case home = "Home"
        case announcements = "Announcements"
        case assignments = "Assignments"
        case discussions = "Discussions"
        case modules = "Modules"
        case grades = "Grades"
        case people = "People"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .announcements: return "megaphone.fill"
            case .assignments: return "doc.text.fill"
            case .discussions: return "bubble.left.and.bubble.right.fill"
            case .modules: return "square.stack.3d.up.fill"
            case .grades: return "chart.bar.fill"
            case .people: return "person.2.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Course Tab", selection: $selectedTab) {
                ForEach(CourseTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
                    switch selectedTab {
                    case .home:
                CourseHomeView(course: course, session: session)
            case .announcements:
                CourseAnnouncementsView(course: course, session: session)
                    case .assignments:
                CourseAssignmentsView(course: course, session: session)
                    case .discussions:
                CourseDiscussionsView(course: course, session: session)
            case .modules:
                CourseModulesView(course: course, session: session)
                    case .grades:
                CourseGradesView(course: course, session: session)
            case .people:
                CoursePeopleView(course: course, session: session)
            }
        }
        .navigationTitle(course.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CourseHomeView: View {
    let course: CanvasCourse
    let session: LoginSession
    @State private var courseDetails: CanvasCourse?
    @State private var frontPage: CanvasPage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        Task {
                            await loadHomePage()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let defaultView = courseDetails?.defaultView {
                switch defaultView {
                case .wiki:
                    if let page = frontPage, let body = page.body, !body.isEmpty {
                        IncrementalImageWebView(htmlString: body, baseURL: session.baseURL, session: session)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height)
                } else {
                        VStack {
                    Text("Welcome to \(course.displayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                                .padding()
                    Text("Course content will appear here")
                        .foregroundColor(.secondary)
                }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                case .modules:
                    CourseModulesView(course: course, session: session)
                case .assignments:
                    CourseAssignmentsView(course: course, session: session)
                case .syllabus:
                    CourseSyllabusView(course: course, session: session)
                case .feed:
                    VStack {
                        Text("Welcome to \(course.displayName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                        Text("Course content will appear here")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                VStack {
                    Text("Welcome to \(course.displayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    Text("Course content will appear here")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            }
        }
        .refreshable {
            await loadHomePage()
        }
        .task {
            await loadHomePage()
        }
    }
    
    private func loadHomePage() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            courseDetails = try await apiService.getCourse(courseId: course.id)
            
            if courseDetails?.defaultView == .wiki {
                frontPage = try await apiService.getFrontPage(courseId: course.id)
            }
        } catch {
            print("Failed to load course home page: \(error)")
            errorMessage = "Failed to load course home page"
        }
        
        isLoading = false
    }
    
    
}

struct CourseModulesView: View {
    let course: CanvasCourse
    let session: LoginSession
    @State private var modules: [CanvasModule] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var collapsedModules: Set<String> = []
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if modules.isEmpty {
                VStack(spacing: 8) {
                    Text("No Modules")
                .font(.headline)
                    Text("There are no modules to display yet.")
                .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                List {
                    ForEach(modules) { module in
                        Section {
                            if let items = module.items, !items.isEmpty {
                                if !collapsedModules.contains(module.id) {
                                    ForEach(items) { item in
                                        ModuleItemRow(item: item, session: session, courseId: course.id)
                                    }
                                }
                            } else {
                                Text("No items")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        } header: {
                            Button {
                                if collapsedModules.contains(module.id) {
                                    collapsedModules.remove(module.id)
                                } else {
                                    collapsedModules.insert(module.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: collapsedModules.contains(module.id) ? "chevron.right" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(module.name)
                                        .font(.headline)
                                    Spacer()
                                    if let published = module.published, !published {
                                        Text("Unpublished")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .task {
            await loadModules()
        }
        .refreshable {
            await loadModules()
        }
    }
    
    private func loadModules() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            modules = try await apiService.getModules(courseId: course.id)
        } catch {
            errorMessage = "Failed to load modules: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ModuleItemRow: View {
    let item: CanvasModuleItem
    let session: LoginSession
    let courseId: String
    
    var iconName: String {
        switch item.type {
        case "Assignment": return "doc.text.fill"
        case "Quiz": return "questionmark.circle.fill"
        case "Discussion": return "bubble.left.and.bubble.right.fill"
        case "Page": return "doc.fill"
        case "File": return "paperclip"
        case "ExternalUrl", "ExternalTool": return "link"
        case "SubHeader": return "text.alignleft"
        default: return "doc.fill"
        }
    }
    
    var isLocked: Bool {
        item.contentDetails?.lockedForUser == true
    }
    
    var isCompleted: Bool {
        item.completionRequirement?.completed == true
    }
    
    var body: some View {
        if isLocked {
            HStack(alignment: .top, spacing: 12) {
                if item.completionRequirement != nil {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .secondary)
                        .font(.system(size: 16))
                }
                
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let dueAt = item.contentDetails?.dueAt {
                        Text(formatDate(dueAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let points = item.contentDetails?.pointsPossible {
                        Text("\(Int(points)) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let explanation = item.contentDetails?.lockExplanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if item.indent > 0 {
                    Spacer()
                        .frame(width: CGFloat(item.indent) * 10)
                }
            }
            .padding(.vertical, 4)
            .opacity(0.6)
        } else {
            NavigationLink {
                ModuleItemContentView(item: item, courseId: courseId, session: session)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    if item.completionRequirement != nil {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isCompleted ? .green : .secondary)
                            .font(.system(size: 16))
                    }
                    
                    Image(systemName: iconName)
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if let dueAt = item.contentDetails?.dueAt {
                            Text(formatDate(dueAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let points = item.contentDetails?.pointsPossible {
                            Text("\(Int(points)) pts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if item.indent > 0 {
                        Spacer()
                            .frame(width: CGFloat(item.indent) * 10)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CourseAnnouncementsView: View {
    let course: CanvasCourse
    let session: LoginSession
    
    @State private var announcements: [CanvasDiscussionTopic] = []
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
                            await loadAnnouncements()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if announcements.isEmpty {
                VStack(spacing: 16) {
                    Text("No Announcements")
                        .font(.headline)
                    Text("There are no announcements in this course.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(announcements) { announcement in
                        AnnouncementRow(announcement: announcement, session: session, courseId: course.id)
                    }
                }
            }
        }
        .task {
            await loadAnnouncements()
        }
        .refreshable {
            await loadAnnouncements()
        }
    }
    
    private func loadAnnouncements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            announcements = try await apiService.getAnnouncements(courseId: course.id)
        } catch {
            errorMessage = "Failed to load announcements: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AnnouncementRow: View {
    let announcement: CanvasDiscussionTopic
    let session: LoginSession
    let courseId: String
    
    var body: some View {
        NavigationLink {
            AnnouncementDetailView(announcement: announcement, courseId: courseId, session: session)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if announcement.pinned == true {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
                
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title ?? "Untitled")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let author = announcement.author {
                        Text(author.displayName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let postedAt = announcement.postedAt {
                        Text(formatDate(postedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if announcement.discussionSubentryCount > 0 {
                        Text("\(announcement.discussionSubentryCount) \(announcement.discussionSubentryCount == 1 ? "reply" : "replies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if announcement.unreadCount ?? 0 > 0 {
                        Text("\(announcement.unreadCount!) unread")
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

struct CoursePagesView: View {
    let course: CanvasCourse
    
    var body: some View {
        VStack {
            Text("Pages")
                .font(.headline)
            Text("Pages will be displayed here")
                .foregroundColor(.secondary)
        }
    }
}

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

struct CourseQuizzesView: View {
    let course: CanvasCourse
    
    var body: some View {
        VStack {
            Text("Quizzes")
                .font(.headline)
            Text("Quizzes will be displayed here")
                .foregroundColor(.secondary)
        }
    }
}

struct CoursePeopleView: View {
    let course: CanvasCourse
    let session: LoginSession
    @State private var enrollments: [CanvasEnrollment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRole: UserRole = .all
    @State private var searchText: String = ""
    
    enum UserRole: String, CaseIterable {
        case all = "All"
        case teacher = "Teacher"
        case student = "Student"
        
        var filterType: String? {
            switch self {
            case .all: return nil
            case .teacher: return "TeacherEnrollment"
            case .student: return "StudentEnrollment"
            }
        }
    }
    
    var uniqueEnrollments: [CanvasEnrollment] {
        var seen = Set<String>()
        return enrollments.filter { enrollment in
            guard let userId = enrollment.userId else { return true }
            if seen.contains(userId) {
                return false
            }
            seen.insert(userId)
            return true
        }
    }
    
    var filteredEnrollments: [CanvasEnrollment] {
        var filtered = uniqueEnrollments
        
        if let filterType = selectedRole.filterType {
            filtered = filtered.filter { $0.type == filterType }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { enrollment in
                guard let user = enrollment.user else { return false }
                return user.name.localizedCaseInsensitiveContains(searchText) ||
                       user.email?.localizedCaseInsensitiveContains(searchText) == true ||
                       user.loginId?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return filtered
    }
    
    var groupedEnrollments: [String: [CanvasEnrollment]] {
        Dictionary(grouping: filteredEnrollments) { enrollment in
            enrollment.role ?? enrollment.type
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !enrollments.isEmpty {
                Picker("Role", selection: $selectedRole) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if let errorMessage = errorMessage {
                VStack {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    Button("Retry") {
                        Task {
                            await loadPeople()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredEnrollments.isEmpty {
                VStack {
                    if searchText.isEmpty {
                Text("No people found")
                    .foregroundColor(.secondary)
            } else {
                        Text("No results for \"\(searchText)\"")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(groupedEnrollments.keys.sorted()), id: \.self) { role in
                        Section(header: Text(role)) {
                            ForEach(groupedEnrollments[role] ?? []) { enrollment in
                                if let user = enrollment.user {
                                    PersonRow(user: user, enrollment: enrollment)
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search people")
        .task {
            await loadPeople()
        }
        .refreshable {
            await loadPeople()
        }
    }
    
    private func loadPeople() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            enrollments = try await apiService.getCourseUsers(courseId: course.id)
        } catch {
            errorMessage = "Failed to load people: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct PersonRow: View {
    let user: CanvasCourseUser
    let enrollment: CanvasEnrollment
    
    var body: some View {
        HStack(spacing: 12) {
            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.gradient)
                        .overlay {
                            Text(user.name.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(user.name.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let loginId = user.loginId {
                    Text(loginId)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let pronouns = user.pronouns {
                Text(pronouns)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CourseSyllabusView: View {
    let course: CanvasCourse
    let session: LoginSession
    @State private var syllabusBody: String?
    @State private var summaryEvents: [CanvasCalendarEvent] = []
    @State private var summaryPlannables: [CanvasPlannable] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: SyllabusTab = .syllabus
    
    enum SyllabusTab: String, CaseIterable {
        case syllabus = "Syllabus"
        case summary = "Summary"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Syllabus Tab", selection: $selectedTab) {
                ForEach(SyllabusTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                switch selectedTab {
                case .syllabus:
                    syllabusContent
                case .summary:
                    summaryContent
                }
            }
        }
        .task {
            await loadSyllabus()
        }
        .refreshable {
            await loadSyllabus()
        }
    }
    
    private var syllabusContent: some View {
        Group {
            if let body = syllabusBody, !body.isEmpty {
                WebView(htmlString: body, baseURL: session.baseURL, session: session)
                    .frame(minHeight: 400)
            } else {
                VStack(spacing: 8) {
                    Text("No Syllabus")
                .font(.headline)
                    Text("There is no syllabus to display.")
                .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
    
    private var summaryContent: some View {
        List {
            if !summaryEvents.isEmpty {
                Section {
                    ForEach(summaryEvents) { event in
                        SummaryItemRow(title: event.title, date: event.startAt, url: event.htmlUrl)
                    }
                } header: {
                    Text("Events")
                }
            }
            
            if !summaryPlannables.isEmpty {
                Section {
                    ForEach(summaryPlannables) { plannable in
                        SummaryItemRow(title: plannable.title ?? "Untitled", date: plannable.plannableDate, url: plannable.htmlUrl)
                    }
                } header: {
                    Text("Assignments")
                }
            }
            
            if summaryEvents.isEmpty && summaryPlannables.isEmpty {
                Section {
                    Text("There are no items to display.")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func loadSyllabus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            let courseDetails = try await apiService.getCourse(courseId: course.id)
            syllabusBody = courseDetails.syllabusBody
            
            let summary = try await apiService.getSyllabusSummary(courseId: course.id)
            summaryEvents = summary.events
            summaryPlannables = summary.plannables
        } catch {
            errorMessage = "Failed to load syllabus: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
}

struct SummaryItemRow: View {
    let title: String
    let date: Date?
    let url: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
            
            if let date = date {
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct WebView: UIViewRepresentable {
    let htmlString: String
    let baseURL: URL
    let session: LoginSession
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 16px;
                    margin: 0;
                    min-height: 100%;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(baseURL: baseURL, session: session)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        var lastHTML: String = ""
        var imageMap: [String: URL] = [:]
        var onImagesLoaded: (([String: URL]) -> Void)?
        
        init(baseURL: URL, session: LoginSession) {
            self.baseURL = baseURL
            self.session = session
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            extractImageURLs(from: webView)
        }
        
        private func extractImageURLs(from webView: WKWebView) {
            let script = """
            (function() {
                var images = document.getElementsByTagName('img');
                var imageMap = {};
                for (var i = 0; i < images.length; i++) {
                    var img = images[i];
                    var src = img.src;
                    if (src && !src.startsWith('data:')) {
                        var imageId = 'img_' + i;
                        img.id = imageId;
                        imageMap[imageId] = src;
                    }
                }
                return imageMap;
            })();
            """
            
            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self,
                      let imageDict = result as? [String: String] else {
                    return
                }
                
                var urlMap: [String: URL] = [:]
                for (imageId, urlString) in imageDict {
                    if let url = URL(string: urlString, relativeTo: self.baseURL) {
                        urlMap[imageId] = url
                    }
                }
                
                self.imageMap = urlMap
                self.onImagesLoaded?(urlMap)
            }
        }
        
        func updateImage(imageId: String, dataURI: String, in webView: WKWebView) {
            let script = """
            (function() {
                var img = document.getElementById('\(imageId)');
                if (img) {
                    img.src = '\(dataURI)';
                }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if url.host == baseURL.host || url.host == nil {
                        decisionHandler(.allow)
                    } else {
                        UIApplication.shared.open(url)
                        decisionHandler(.cancel)
                    }
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct IncrementalImageWebView: UIViewRepresentable {
    let htmlString: String
    let baseURL: URL
    let session: LoginSession
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 16px;
                    margin: 0;
                    min-height: 100%;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            context.coordinator.imageMap = [:]
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> IncrementalImageCoordinator {
        IncrementalImageCoordinator(baseURL: baseURL, session: session)
    }
    
    class IncrementalImageCoordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        var lastHTML: String = ""
        var imageMap: [String: URL] = [:]
        weak var webView: WKWebView?
        
        init(baseURL: URL, session: LoginSession) {
            self.baseURL = baseURL
            self.session = session
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
            extractImageURLs(from: webView)
        }
        
        private func extractImageURLs(from webView: WKWebView) {
            let script = """
            (function() {
                var images = document.getElementsByTagName('img');
                var imageMap = {};
                for (var i = 0; i < images.length; i++) {
                    var img = images[i];
                    var src = img.src;
                    if (src && !src.startsWith('data:')) {
                        var imageId = 'img_' + i;
                        img.id = imageId;
                        imageMap[imageId] = src;
                    }
                }
                return imageMap;
            })();
            """
            
            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self,
                      let imageDict = result as? [String: String] else {
                    return
                }
                
                var urlMap: [String: URL] = [:]
                for (imageId, urlString) in imageDict {
                    if let url = URL(string: urlString, relativeTo: self.baseURL) {
                        urlMap[imageId] = url
                    }
                }
                
                self.imageMap = urlMap
                Task.detached(priority: .userInitiated) {
                    await self.loadImagesIncrementally(imageMap: urlMap)
                }
            }
        }
        
        private func loadImagesIncrementally(imageMap: [String: URL]) async {
            await withTaskGroup(of: (String, String)?.self) { group in
                for (imageId, imageURL) in imageMap {
                    group.addTask {
                        if let dataURI = await self.downloadImageAsDataURI(url: imageURL) {
                            return (imageId, dataURI)
                        }
                        return nil
                    }
                }
                
                for await result in group {
                    if let (imageId, dataURI) = result {
                        await MainActor.run {
                            self.updateImage(imageId: imageId, dataURI: dataURI)
                        }
                    }
                }
            }
        }
        
        private func downloadImageAsDataURI(url: URL) async -> String? {
            let absoluteURL = url.absoluteURL.standardized
            
            var request = URLRequest(url: absoluteURL)
            if let token = session.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    return nil
                }
                
                let mimeType = httpResponse.mimeType ?? "image/png"
                let base64 = data.base64EncodedString()
                return "data:\(mimeType);base64,\(base64)"
            } catch {
                print("Failed to download image \(url.absoluteString): \(error)")
                return nil
            }
        }
        
        private func updateImage(imageId: String, dataURI: String) {
            guard let webView = webView else { return }
            let escapedDataURI = dataURI.replacingOccurrences(of: "'", with: "\\'")
            let script = """
            (function() {
                var img = document.getElementById('\(imageId)');
                if (img) {
                    img.src = '\(escapedDataURI)';
                }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if url.host == baseURL.host || url.host == nil {
                        decisionHandler(.allow)
                    } else {
                        UIApplication.shared.open(url)
                        decisionHandler(.cancel)
                    }
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct ModuleItemContentView: View {
    let item: CanvasModuleItem
    let courseId: String
    let session: LoginSession
    
    var body: some View {
        Group {
            switch item.type {
            case "File":
                if let fileId = item.contentId {
                    ModuleItemFileView(fileId: fileId, courseId: courseId, baseURL: session.baseURL, session: session, title: item.title)
                        .navigationTitle(item.title)
                } else if let url = item.url ?? item.htmlUrl {
                    ModuleItemFileView(url: url, baseURL: session.baseURL, session: session, title: item.title)
                        .navigationTitle(item.title)
                } else {
                    errorView
                }
            case "Page":
                ModuleItemPageView(item: item, courseId: courseId, session: session)
                    .navigationTitle(item.title)
            case "Assignment":
                if let assignmentId = item.contentId {
                    ModuleItemAssignmentView(assignmentId: assignmentId, courseId: courseId, session: session)
                } else if let assignmentId = extractAssignmentId() {
                    ModuleItemAssignmentView(assignmentId: assignmentId, courseId: courseId, session: session)
                } else if let url = item.url ?? item.htmlUrl {
                    ModuleItemWebView(url: url, baseURL: session.baseURL, session: session, title: item.title)
                        .navigationTitle(item.title)
                } else {
                    errorView
                }
            case "Quiz", "Discussion":
                if let url = item.url ?? item.htmlUrl {
                    ModuleItemWebView(url: url, baseURL: session.baseURL, session: session, title: item.title)
                        .navigationTitle(item.title)
                } else {
                    errorView
                }
            default:
                if let url = item.url ?? item.htmlUrl {
                    ModuleItemWebView(url: url, baseURL: session.baseURL, session: session, title: item.title)
                        .navigationTitle(item.title)
                } else {
                    errorView
                }
            }
        }
    }
    
    private var errorView: some View {
        VStack {
            Text("Unable to load content")
                .foregroundColor(.secondary)
            Text("No URL available for this item")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(item.title)
    }
    
    private func extractAssignmentId() -> String? {
        if let apiURL = item.url {
            let pathComponents = apiURL.pathComponents
            if let assignmentsIndex = pathComponents.firstIndex(of: "assignments"),
               assignmentsIndex + 1 < pathComponents.count {
                return pathComponents[assignmentsIndex + 1]
            }
        }
        if let htmlURL = item.htmlUrl {
            let pathComponents = htmlURL.pathComponents
            if let assignmentsIndex = pathComponents.firstIndex(of: "assignments"),
               assignmentsIndex + 1 < pathComponents.count {
                return pathComponents[assignmentsIndex + 1]
            }
        }
        return nil
    }
}

struct ModuleItemAssignmentView: View {
    let assignmentId: String
    let courseId: String
    let session: LoginSession
    
    @State private var assignment: CanvasAssignment?
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
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadAssignment()
                        }
                    }
                }
                .padding()
                .navigationTitle("Assignment")
            } else if let assignment = assignment {
                AssignmentDetailView(assignment: assignment, courseId: courseId, session: session)
            } else {
                Text("Unable to load assignment")
                    .foregroundColor(.secondary)
                    .padding()
                    .navigationTitle("Assignment")
            }
        }
        .task {
            await loadAssignment()
        }
    }
    
    private func loadAssignment() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            assignment = try await apiService.getAssignment(courseId: courseId, assignmentId: assignmentId)
        } catch {
            errorMessage = "Failed to load assignment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ModuleItemWebView: UIViewRepresentable {
    let url: URL
    let baseURL: URL
    let session: LoginSession
    let title: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.ensureLoaded(webView: webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.originalURL != url {
            context.coordinator.originalURL = url
            context.coordinator.loadWebSession(webView: webView)
        } else if context.coordinator.needsInitialLoad {
            context.coordinator.needsInitialLoad = false
            context.coordinator.loadWebSession(webView: webView)
        }
    }
    
    func makeCoordinator() -> ModuleItemWebViewCoordinator {
        ModuleItemWebViewCoordinator(baseURL: baseURL, session: session, originalURL: url)
    }
    
    class ModuleItemWebViewCoordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        var originalURL: URL
        var needsInitialLoad = true
        
        init(baseURL: URL, session: LoginSession, originalURL: URL) {
            self.baseURL = baseURL
            self.session = session
            self.originalURL = originalURL
        }
        
        func ensureLoaded(webView: WKWebView) {
            if needsInitialLoad {
                needsInitialLoad = false
                DispatchQueue.main.async {
                    self.loadWebSession(webView: webView)
                }
            }
        }
        
        func loadWebSession(webView: WKWebView) {
            Task {
                do {
                    let apiService = CanvasAPIService(session: session)
                    let sessionURL = try await apiService.getWebSession(to: originalURL)
                    
                    await MainActor.run {
                        let request = URLRequest(url: sessionURL)
                        webView.load(request)
                    }
                } catch {
                    print("Failed to get web session: \(error)")
                    await MainActor.run {
                        let request = URLRequest(url: originalURL)
                        webView.load(request)
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct ModuleItemFileView: UIViewRepresentable {
    let fileId: String?
    let courseId: String?
    let url: URL?
    let baseURL: URL
    let session: LoginSession
    let title: String
    
    init(fileId: String, courseId: String, baseURL: URL, session: LoginSession, title: String) {
        self.fileId = fileId
        self.courseId = courseId
        self.url = nil
        self.baseURL = baseURL
        self.session = session
        self.title = title
    }
    
    init(url: URL, baseURL: URL, session: LoginSession, title: String) {
        self.fileId = nil
        self.courseId = nil
        self.url = url
        self.baseURL = baseURL
        self.session = session
        self.title = title
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.ensureLoaded(webView: webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let currentURL = url ?? context.coordinator.fileURL
        if let currentURL = currentURL, context.coordinator.originalURL != currentURL {
            context.coordinator.originalURL = currentURL
            context.coordinator.loadFile(webView: webView)
        } else if context.coordinator.needsInitialLoad {
            context.coordinator.needsInitialLoad = false
            context.coordinator.loadFile(webView: webView)
        }
    }
    
    func makeCoordinator() -> ModuleItemFileViewCoordinator {
        ModuleItemFileViewCoordinator(fileId: fileId, courseId: courseId, url: url, baseURL: baseURL, session: session)
    }
    
    class ModuleItemFileViewCoordinator: NSObject, WKNavigationDelegate {
        let fileId: String?
        let courseId: String?
        var url: URL?
        let baseURL: URL
        let session: LoginSession
        var originalURL: URL?
        var fileURL: URL?
        var needsInitialLoad = true
        
        init(fileId: String?, courseId: String?, url: URL?, baseURL: URL, session: LoginSession) {
            self.fileId = fileId
            self.courseId = courseId
            self.url = url
            self.baseURL = baseURL
            self.session = session
        }
        
        func ensureLoaded(webView: WKWebView) {
            if needsInitialLoad {
                needsInitialLoad = false
                DispatchQueue.main.async {
                    self.loadFile(webView: webView)
                }
            }
        }
        
        func loadFile(webView: WKWebView) {
            Task {
                var targetURL: URL?
                
                if let fileId = fileId, let courseId = courseId {
                    do {
                        let apiService = CanvasAPIService(session: session)
                        let file = try await apiService.getFile(courseId: courseId, fileId: fileId)
                        if let fileDownloadURL = file.url {
                            targetURL = fileDownloadURL
                            self.fileURL = fileDownloadURL
                        } else {
                            let fileDownloadURL = baseURL.appendingPathComponent("api/v1/courses/\(courseId)/files/\(fileId)/download")
                            targetURL = fileDownloadURL
                            self.fileURL = fileDownloadURL
                        }
                    } catch {
                        let fileDownloadURL = baseURL.appendingPathComponent("api/v1/courses/\(courseId)/files/\(fileId)/download")
                        targetURL = fileDownloadURL
                        self.fileURL = fileDownloadURL
                    }
                } else if let url = url {
                    if url.pathComponents.contains("files") && !url.pathComponents.contains("download") {
                        targetURL = url.appendingPathComponent("download")
                        fileURL = targetURL
                    } else {
                        targetURL = url
                        fileURL = url
                    }
                }
                
                guard let targetURL = targetURL else { return }
                originalURL = targetURL
                
                await MainActor.run {
                    var request = URLRequest(url: targetURL)
                    if let token = session.accessToken {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
                    webView.load(request)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct ModuleItemPageView: View {
    let item: CanvasModuleItem
    let courseId: String
    let session: LoginSession
    @State private var page: CanvasPage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let page = page, let body = page.body, !body.isEmpty {
                ScrollView {
                    IncrementalImageWebView(htmlString: body, baseURL: session.baseURL, session: session)
                        .frame(minHeight: 400)
                }
            } else {
                Text("Unable to load page")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .task {
            await loadPage()
        }
    }
    
    private func loadPage() async {
        isLoading = true
        do {
            let apiService = CanvasAPIService(session: session)
            if let pageURL = item.pageId {
                if pageURL == "front_page" {
                    page = try await apiService.getFrontPage(courseId: courseId)
                } else {
                    page = try await apiService.getPage(courseId: courseId, pageURL: pageURL)
                }
            } else if let url = item.url {
                let pathComponents = url.pathComponents
                if let pageIndex = pathComponents.firstIndex(of: "pages"),
                   pageIndex + 1 < pathComponents.count {
                    let pageURL = pathComponents[pageIndex + 1]
                    if pageURL == "front_page" {
                        page = try await apiService.getFrontPage(courseId: courseId)
                    } else {
                        page = try await apiService.getPage(courseId: courseId, pageURL: pageURL)
                    }
                }
            }
        } catch {
            print("Failed to load page: \(error)")
        }
        isLoading = false
    }
}




