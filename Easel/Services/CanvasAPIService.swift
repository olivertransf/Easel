//
//  CanvasAPIService.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation
import UIKit

class CanvasAPIService {
    private let baseURL: URL
    private let accessToken: String?
    private let cookies: [HTTPCookie]?
    var extractedToken: String?
    
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024, diskPath: "easel_cache")
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
    
    init(canvasURL: String, accessToken: String?, cookies: [HTTPCookie]? = nil) {
        self.baseURL = URL(string: canvasURL) ?? URL(string: "https://canvas.instructure.com/")!
        self.accessToken = accessToken
        self.cookies = cookies
    }
    
    init(session: LoginSession) {
        self.baseURL = session.baseURL
        self.accessToken = session.accessToken
        self.cookies = nil
    }
    
    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        guard var components = URLComponents(string: path) else { return nil }
        
        if !path.hasPrefix("/") && components.host == nil {
            components.path = "/api/v1/" + components.path
        }
        
        var allQueryItems = queryItems
        allQueryItems.append(URLQueryItem(name: "no_verifiers", value: "1"))
        components.queryItems = allQueryItems
        
        guard let url = components.url(relativeTo: baseURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
        
        if let token = accessToken, url.host == baseURL.host {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let cookies = cookies {
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let version = UIDevice.current.systemVersion
        let product = "iCanvas"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let userAgent = "\(product)/\(shortVersion) (\(bundleVersion)) \(UIDevice.current.model)/\(UIDevice.current.systemName) \(version)"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    func getCurrentUser() async throws -> CanvasUser {
        guard let request = makeRequest(path: "users/self") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let user = try JSONDecoder().decode(CanvasUser.self, from: data)
        return user
    }
    
    func getCourses() async throws -> [CanvasCourse] {
        guard let request = makeRequest(
            path: "courses",
            queryItems: [
                URLQueryItem(name: "enrollment_type", value: "student"),
                URLQueryItem(name: "enrollment_state", value: "active"),
                URLQueryItem(name: "state[]", value: "available"),
                URLQueryItem(name: "include", value: "favorites"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("API Error Response: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            var courses = try decoder.decode([CanvasCourse].self, from: data)
            
            courses = courses.filter { course in
                guard let workflowState = course.workflowState else {
                    return true
                }
                return workflowState == "available" || workflowState == "active"
            }
            
            return courses
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode courses. Response: \(jsonString.prefix(1000))")
            }
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
            throw error
        }
    }
    
    func getCourse(courseId: String) async throws -> CanvasCourse {
        guard let request = makeRequest(
            path: "courses/\(courseId)",
            queryItems: [
                URLQueryItem(name: "include[]", value: "syllabus_body")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let course = try JSONDecoder().decode(CanvasCourse.self, from: data)
        return course
    }
    
    func getCourseUsers(courseId: String) async throws -> [CanvasEnrollment] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/enrollments",
            queryItems: [
                URLQueryItem(name: "include[]", value: "user"),
                URLQueryItem(name: "include[]", value: "avatar_url"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Enrollments API Error: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let enrollments = try JSONDecoder().decode([CanvasEnrollment].self, from: data)
            return enrollments
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode enrollments. Response: \(jsonString.prefix(1000))")
            }
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
            throw error
        }
    }
    
    func getModules(courseId: String) async throws -> [CanvasModule] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/modules",
            queryItems: [
                URLQueryItem(name: "include[]", value: "items"),
                URLQueryItem(name: "include[]", value: "content_details"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        var modules = try JSONDecoder().decode([CanvasModule].self, from: data)
        
        for index in modules.indices {
            let module = modules[index]
            let items = try await getModuleItems(courseId: courseId, moduleId: module.id)
            modules[index].items = items
        }
        
        return modules
    }
    
    private func getModuleItems(courseId: String, moduleId: String) async throws -> [CanvasModuleItem] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/modules/\(moduleId)/items",
            queryItems: [
                URLQueryItem(name: "include[]", value: "content_details"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([CanvasModuleItem].self, from: data)
    }
    
    func getSyllabusSummary(courseId: String) async throws -> (events: [CanvasCalendarEvent], plannables: [CanvasPlannable]) {
        let courseContext = "course_\(courseId)"
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let eventsRequest = makeRequest(
            path: "calendar_events",
            queryItems: [
                URLQueryItem(name: "type", value: "event"),
                URLQueryItem(name: "context_codes[]", value: courseContext),
                URLQueryItem(name: "start_date", value: dateFormatter.string(from: startDate)),
                URLQueryItem(name: "end_date", value: dateFormatter.string(from: endDate)),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ),
        let plannablesRequest = makeRequest(
            path: "users/self/planner/items",
            queryItems: [
                URLQueryItem(name: "filter[course_id]", value: String(courseId)),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        async let eventsTask = Self.urlSession.data(for: eventsRequest)
        async let plannablesTask = Self.urlSession.data(for: plannablesRequest)
        
        let (eventsDataResult, eventsResponseResult) = try await eventsTask
        let (plannablesDataResult, plannablesResponseResult) = try await plannablesTask
        
        guard let eventsHttpResponse = eventsResponseResult as? HTTPURLResponse,
              let plannablesHttpResponse = plannablesResponseResult as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard eventsHttpResponse.statusCode == 200, plannablesHttpResponse.statusCode == 200 else {
            throw APIError.httpError(eventsHttpResponse.statusCode != 200 ? eventsHttpResponse.statusCode : plannablesHttpResponse.statusCode)
        }
        
        let events = try JSONDecoder().decode([CanvasCalendarEvent].self, from: eventsDataResult)
        let plannables = try JSONDecoder().decode([CanvasPlannable].self, from: plannablesDataResult)
        
        return (events.filter { $0.hidden != true }, plannables)
    }
    
    func getPage(courseId: String, pageURL: String) async throws -> CanvasPage {
        guard let request = makeRequest(path: "courses/\(courseId)/pages/\(pageURL.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pageURL)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CanvasPage.self, from: data)
    }
    
    func getFrontPage(courseId: String) async throws -> CanvasPage {
        guard let request = makeRequest(path: "courses/\(courseId)/front_page") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let page = try JSONDecoder().decode(CanvasPage.self, from: data)
        return page
    }
    
    func getAnnouncements(courseId: String) async throws -> [CanvasDiscussionTopic] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/discussion_topics",
            queryItems: [
                URLQueryItem(name: "only_announcements", value: "1"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([CanvasDiscussionTopic].self, from: data)
    }
    
    func getAssignments(courseId: String) async throws -> [CanvasAssignment] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/assignments",
            queryItems: [
                URLQueryItem(name: "include[]", value: "submission"),
                URLQueryItem(name: "order_by", value: "position"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([CanvasAssignment].self, from: data)
    }
    
    func getDiscussions(courseId: String) async throws -> [CanvasDiscussionTopic] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/discussion_topics",
            queryItems: [
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Discussions API Error Response: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let allTopics = try decoder.decode([CanvasDiscussionTopic].self, from: data)
            let discussions = allTopics.filter { topic in
                topic.subscriptionHold != "topic_is_announcement"
            }
            return discussions
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode discussions. Response: \(jsonString.prefix(1000))")
            }
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
            throw error
        }
    }
    
    func getAssignment(courseId: String, assignmentId: String) async throws -> CanvasAssignment {
        guard let request = makeRequest(
            path: "courses/\(courseId)/assignments/\(assignmentId)",
            queryItems: [
                URLQueryItem(name: "include[]", value: "submission")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CanvasAssignment.self, from: data)
    }
    
    func getGrades(courseId: String) async throws -> [CanvasAssignment] {
        guard let request = makeRequest(
            path: "courses/\(courseId)/assignments",
            queryItems: [
                URLQueryItem(name: "include[]", value: "submission"),
                URLQueryItem(name: "order_by", value: "position"),
                URLQueryItem(name: "per_page", value: "100")
            ]
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let allAssignments = try JSONDecoder().decode([CanvasAssignment].self, from: data)
        return allAssignments.filter { assignment in
            assignment.pointsPossible != nil && assignment.pointsPossible! > 0
        }
    }
    
    func getDiscussionTopic(courseId: String, topicId: String) async throws -> CanvasDiscussionTopic {
        guard let request = makeRequest(
            path: "courses/\(courseId)/discussion_topics/\(topicId)",
            queryItems: []
        ) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CanvasDiscussionTopic.self, from: data)
    }
    
    struct WebSessionResponse: Codable {
        let session_url: URL
        let requires_terms_acceptance: Bool?
    }
    
    func getWebSession(to url: URL) async throws -> URL {
        var returnToURL = url
        returnToURL = returnToURL.appendingQueryItems(URLQueryItem(name: "display", value: "borderless"))
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/login/session_token"
        components?.queryItems = [
            URLQueryItem(name: "return_to", value: returnToURL.absoluteString)
        ]
        
        guard let sessionTokenURL = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: sessionTokenURL)
        request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let version = UIDevice.current.systemVersion
        let product = "iCanvas"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let userAgent = "\(product)/\(shortVersion) (\(bundleVersion)) \(UIDevice.current.model)/\(UIDevice.current.systemName) \(version)"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Web session API Error Response: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let sessionResponse = try JSONDecoder().decode(WebSessionResponse.self, from: data)
        return sessionResponse.session_url
    }
    
    func getFile(courseId: String, fileId: String) async throws -> CanvasFile {
        guard let request = makeRequest(path: "courses/\(courseId)/files/\(fileId)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await Self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("File API Error Response: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CanvasFile.self, from: data)
    }
}

extension URL {
    func appendingQueryItems(_ items: URLQueryItem...) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(contentsOf: items)
        components?.queryItems = queryItems
        return components?.url ?? self
    }
}

