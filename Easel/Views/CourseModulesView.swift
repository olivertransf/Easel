//
//  CourseModulesView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

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

