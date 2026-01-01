//
//  HomeView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import Inject

struct HomeView: View {
    @ObserveInjection var iO
    @ObservedObject var loginService: LoginService
    let session: LoginSession
    @State private var courses: [CanvasCourse] = []
    @State private var isLoadingCourses = false
    @AppStorage("showStarredOnly") private var showStarredOnly = false
    @State private var selectedCourse: CanvasCourse?
    
    var filteredCourses: [CanvasCourse] {
        if showStarredOnly {
            return courses.filter { $0.isFavorite == true }
        }
        return courses
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if let selectedCourse = selectedCourse {
                        CourseDetailView(course: selectedCourse, loginService: loginService, session: session, onBack: {
                            self.selectedCourse = nil
                        })
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                coursesSection()
                            }
                            .padding()
                        }
                        .navigationTitle("Courses")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    Task {
                                        await loadCourses()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                        }
                        .task {
                            await loadCourses()
                        }
                        .refreshable {
                            await loadCourses()
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            TodosView(session: session)
                .tabItem {
                    Label("Todos", systemImage: "checklist")
                }
            
            CalendarView(session: session)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            NotificationsView(session: session)
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
            
            SettingsView(loginService: loginService, session: session)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .enableInjection()
    }
    
    @ViewBuilder
    private func coursesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Courses")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(showStarredOnly ? .yellow : .gray)
                        .font(.subheadline)
                    
                    Toggle("", isOn: $showStarredOnly)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 4)
            
            if isLoadingCourses {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if filteredCourses.isEmpty {
                Text(showStarredOnly ? "No starred courses" : "No courses found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredCourses) { course in
                        Button {
                            selectedCourse = course
                        } label: {
                            CourseRow(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func loadCourses() async {
        isLoadingCourses = true
        
        do {
            let apiService = CanvasAPIService(session: session)
            courses = try await apiService.getCourses()
        } catch {
            print("Failed to load courses: \(error.localizedDescription)")
        }
        
        isLoadingCourses = false
    }
}

struct CourseRow: View {
    @ObserveInjection var iO
    let course: CanvasCourse
    
    var body: some View {
        HStack {
            if course.isFavorite == true {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let courseCode = course.courseCode, courseCode != course.displayName {
                    Text(courseCode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let percentage = course.currentScorePercentage {
                HStack(spacing: 4) {
                    if course.isGradeLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: "%.2f%%", percentage))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            } else if let grade = course.currentGrade {
                HStack(spacing: 4) {
                    if course.isGradeLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(grade)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .enableInjection()
    }
}


