//
//  HomeView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var loginService: LoginService
    let session: LoginSession
    @State private var courses: [CanvasCourse] = []
    @State private var isLoadingCourses = false
    @State private var showStarredOnly = false
    
    var filteredCourses: [CanvasCourse] {
        if showStarredOnly {
            return courses.filter { $0.isFavorite == true }
        }
        return courses
    }
    
    var body: some View {
        TabView {
            NavigationStack {
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
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            SettingsView(loginService: loginService, session: session)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
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
                        NavigationLink(destination: CourseDetailView(course: course, loginService: loginService, session: session)) {
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
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


