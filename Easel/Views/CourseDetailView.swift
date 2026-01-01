//
//  CourseDetailView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import Inject

struct CourseDetailView: View {
    @ObserveInjection var iO
    let course: CanvasCourse
    @ObservedObject var loginService: LoginService
    let session: LoginSession
    let onBack: () -> Void
    @State private var selectedTab: CourseTab = .home
    @State private var navigationPath = NavigationPath()
    
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
        NavigationStack(path: $navigationPath) {
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
                    CourseHomeView(course: course, session: session, navigationPath: $navigationPath)
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
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                destinationView(for: destination, navigationPath: $navigationPath)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if navigationPath.isEmpty {
                        Button {
                            onBack()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Courses")
                            }
                        }
                    }
                }
            }
        }
        .enableInjection()
    }
    
    @ViewBuilder
    private func destinationView(for destination: HomeNavigationDestination, navigationPath: Binding<NavigationPath>) -> some View {
        switch destination {
        case .assignment(let assignmentId, let courseId):
            ModuleItemAssignmentView(assignmentId: assignmentId, courseId: courseId, session: session)
        case .discussion(let discussionId, let courseId):
            DiscussionDetailViewWrapper(discussionId: discussionId, courseId: courseId, session: session)
        case .page(let pageUrl, let courseId):
            ModuleItemPageViewWrapper(pageUrl: pageUrl, courseId: courseId, session: session, navigationPath: navigationPath)
        case .module(_, let courseId):
            CourseModulesView(course: CanvasCourse(id: courseId), session: session)
                .navigationTitle("Modules")
                .navigationBarTitleDisplayMode(.inline)
        case .file(let fileId, let courseId):
            ModuleItemFileView(fileId: fileId, courseId: courseId, baseURL: session.baseURL, session: session, title: "")
        }
    }
}
