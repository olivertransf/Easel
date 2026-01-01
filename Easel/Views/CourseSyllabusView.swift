//
//  CourseSyllabusView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

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

