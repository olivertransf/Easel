//
//  CourseHomeView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct CourseHomeView: View {
    let course: CanvasCourse
    let session: LoginSession
    @Binding var navigationPath: NavigationPath
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
                            IncrementalImageWebView(
                                htmlString: body,
                                baseURL: session.baseURL,
                                session: session,
                                courseId: course.id,
                                navigationPath: $navigationPath
                            )
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

