//
//  CoursePeopleView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

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

