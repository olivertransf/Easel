//
//  ModuleItemViews.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct DiscussionDetailViewWrapper: View {
    let discussionId: String
    let courseId: String
    let session: LoginSession
    @State private var discussion: CanvasDiscussionTopic?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadDiscussion()
                        }
                    }
                }
                .padding()
            } else if let discussion = discussion {
                DiscussionDetailView(discussion: discussion, courseId: courseId, session: session)
            } else {
                Text("Discussion not found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .task {
            await loadDiscussion()
        }
    }
    
    private func loadDiscussion() async {
        isLoading = true
        errorMessage = nil
        
        let cleanedDiscussionId = discussionId.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Loading discussion with ID: '\(cleanedDiscussionId)' for course: \(courseId)")
        
        guard !cleanedDiscussionId.isEmpty else {
            errorMessage = "Invalid discussion ID"
            isLoading = false
            return
        }
        
        do {
            let apiService = CanvasAPIService(session: session)
            print("Attempting to load discussion ID '\(cleanedDiscussionId)' from course '\(courseId)'")
            discussion = try await apiService.getDiscussionTopic(courseId: courseId, topicId: cleanedDiscussionId)
            print("Successfully loaded discussion: \(discussion?.title ?? "Unknown")")
        } catch let error as APIError {
            print("API Error loading discussion: \(error)")
            if case .httpError(let code) = error {
                switch code {
                case 404:
                    print("404 error - attempting fallback: searching discussions list...")
                    do {
                        let apiService = CanvasAPIService(session: session)
                        let allDiscussions = try await apiService.getDiscussions(courseId: courseId)
                        print("Found \(allDiscussions.count) discussions in course")
                        print("Looking for discussion with ID: \(cleanedDiscussionId)")
                        print("Available IDs: \(allDiscussions.map { $0.id }.prefix(10).joined(separator: ", "))")
                        
                        if let found = allDiscussions.first(where: { $0.id == cleanedDiscussionId }) {
                            print("Found discussion in list: \(found.title ?? "Untitled")")
                            discussion = found
                            return
                        } else {
                            errorMessage = "Discussion not found. The discussion may have been deleted, moved, or you may not have access. Discussion ID: \(cleanedDiscussionId)"
                        }
                    } catch {
                        print("Fallback search failed: \(error)")
                        errorMessage = "Discussion not found (ID: \(cleanedDiscussionId)). It may have been deleted or you may not have access."
                    }
                case 403:
                    errorMessage = "You don't have permission to view this discussion."
                case 401:
                    errorMessage = "Please log in again to view this discussion."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            errorMessage = "Failed to parse discussion data. The discussion format may be unsupported."
        } catch {
            print("Error loading discussion: \(error)")
            errorMessage = "Failed to load discussion: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ModuleItemPageViewWrapper: View {
    let pageUrl: String
    let courseId: String
    let session: LoginSession
    @Binding var navigationPath: NavigationPath
    @State private var page: CanvasPage?
    @State private var isLoading = true
    @State private var innerNavigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $innerNavigationPath) {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let page = page, let body = page.body, !body.isEmpty {
                    ScrollView {
                        IncrementalImageWebView(
                            htmlString: body,
                            baseURL: session.baseURL,
                            session: session,
                            courseId: courseId,
                            navigationPath: $innerNavigationPath
                        )
                        .frame(minHeight: 400)
                    }
                } else {
                    Text("Unable to load page")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                destinationView(for: destination, parentNavigationPath: $navigationPath)
            }
        }
        .task {
            await loadPage()
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: HomeNavigationDestination, parentNavigationPath: Binding<NavigationPath>) -> some View {
        switch destination {
        case .assignment(let assignmentId, let destCourseId):
            ModuleItemAssignmentView(assignmentId: assignmentId, courseId: destCourseId, session: session)
        case .discussion(let discussionId, let destCourseId):
            DiscussionDetailViewWrapper(discussionId: discussionId, courseId: destCourseId, session: session)
        case .page(let pageUrl, let destCourseId):
            ModuleItemPageViewWrapper(pageUrl: pageUrl, courseId: destCourseId, session: session, navigationPath: parentNavigationPath)
        case .module(_, let destCourseId):
            CourseModulesView(course: CanvasCourse(id: destCourseId), session: session)
                .navigationTitle("Modules")
                .navigationBarTitleDisplayMode(.inline)
        case .file(let fileId, let destCourseId):
            ModuleItemFileView(fileId: fileId, courseId: destCourseId, baseURL: session.baseURL, session: session, title: "")
        }
    }
    
    private func loadPage() async {
        isLoading = true
        do {
            let apiService = CanvasAPIService(session: session)
            if pageUrl == "front_page" {
                page = try await apiService.getFrontPage(courseId: courseId)
            } else {
                page = try await apiService.getPage(courseId: courseId, pageURL: pageUrl)
            }
        } catch {
            print("Failed to load page: \(error)")
        }
        isLoading = false
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
                    IncrementalImageWebView(
                        htmlString: body,
                        baseURL: session.baseURL,
                        session: session,
                        courseId: courseId,
                        navigationPath: .constant(NavigationPath())
                    )
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

