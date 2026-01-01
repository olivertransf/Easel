//
//  CourseNavigation.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

enum HomeNavigationDestination: Hashable {
    case assignment(String, courseId: String)
    case discussion(String, courseId: String)
    case page(String, courseId: String)
    case module(String, courseId: String)
    case file(String, courseId: String)
}

struct CanvasURLParser {
    let baseURL: URL
    let courseId: String
    
    func parse(url: URL) -> HomeNavigationDestination? {
        guard url.host == baseURL.host || url.host == nil else {
            return nil
        }
        
        var urlToParse = url
        if url.host == nil {
            if let absoluteURL = URL(string: url.absoluteString, relativeTo: baseURL) {
                urlToParse = absoluteURL
            } else if url.path.hasPrefix("/") {
                urlToParse = baseURL.appendingPathComponent(url.path)
                if let query = url.query {
                    var components = URLComponents(url: urlToParse, resolvingAgainstBaseURL: false)
                    components?.query = query
                    if let newURL = components?.url {
                        urlToParse = newURL
                    }
                }
            }
        }
        
        let pathComponents = urlToParse.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        
        print("Parsing URL: \(urlToParse.absoluteString)")
        print("Path components: \(pathComponents)")
        if let query = urlToParse.query {
            print("Query parameters: \(query)")
        }
        
        guard let coursesIndex = pathComponents.firstIndex(of: "courses"),
              coursesIndex + 1 < pathComponents.count else {
            print("No courses found in path")
            return nil
        }
        
        let urlCourseId = pathComponents[coursesIndex + 1]
        if urlCourseId != courseId {
            print("Course ID mismatch: expected \(courseId), got \(urlCourseId) - will try anyway")
        }
        
        var index = coursesIndex + 2
        
        while index < pathComponents.count {
            let component = pathComponents[index]
            
            switch component {
            case "assignments":
                if index + 1 < pathComponents.count {
                    let assignmentId = pathComponents[index + 1]
                    if assignmentId != "syllabus" {
                        print("Found assignment: \(assignmentId) in course: \(urlCourseId)")
                        return .assignment(assignmentId, courseId: urlCourseId)
                    }
                }
            case "discussion_topics":
                if index + 1 < pathComponents.count {
                    var discussionId = pathComponents[index + 1]
                    if let querySeparator = discussionId.firstIndex(of: "?") {
                        discussionId = String(discussionId[..<querySeparator])
                    }
                    if let fragmentSeparator = discussionId.firstIndex(of: "#") {
                        discussionId = String(discussionId[..<fragmentSeparator])
                    }
                    if discussionId != "new" && !discussionId.isEmpty {
                        print("Found discussion: \(discussionId) in course: \(urlCourseId)")
                        print("Full URL path: \(urlToParse.path)")
                        print("Discussion ID after cleaning: '\(discussionId)'")
                        return .discussion(discussionId, courseId: urlCourseId)
                    }
                }
            case "pages":
                if index + 1 < pathComponents.count {
                    let pageUrl = pathComponents[index + 1]
                    print("Found page: \(pageUrl) in course: \(urlCourseId)")
                    return .page(pageUrl, courseId: urlCourseId)
                }
            case "modules":
                if index + 1 < pathComponents.count {
                    let moduleId = pathComponents[index + 1]
                    print("Found module: \(moduleId) in course: \(urlCourseId)")
                    return .module(moduleId, courseId: urlCourseId)
                }
            case "files":
                if index + 1 < pathComponents.count {
                    let fileId = pathComponents[index + 1]
                    if fileId != "download" && fileId != "preview" {
                        print("Found file: \(fileId) in course: \(urlCourseId)")
                        return .file(fileId, courseId: urlCourseId)
                    }
                }
            default:
                break
            }
            
            index += 1
        }
        
        print("No matching resource found in URL")
        return nil
    }
}

