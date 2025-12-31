import Foundation
import UIKit

class MobileVerifyService {
    private let verifyURL = "https://canvas.instructure.com/api/v1/mobile_verify.json"
    
    func getMobileVerify(domain: String) async throws -> MobileVerifyResponse {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        print("MobileVerifyService: Requesting mobile verify for domain: '\(cleanDomain)'")
        
        return try await performMobileVerify(domain: cleanDomain)
    }
    
    private func performMobileVerify(domain: String) async throws -> MobileVerifyResponse {
        var components = URLComponents(string: verifyURL)
        components?.queryItems = [
            URLQueryItem(name: "domain", value: domain)
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        print("MobileVerifyService: Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let version = UIDevice.current.systemVersion
        let product = "iCanvas"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""
        let userAgent = "\(product)/\(shortVersion) (\(bundleVersion)) \(UIDevice.current.model)/\(UIDevice.current.systemName) \(version)"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Mobile verify error response: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Mobile verify raw response: \(jsonString)")
        }
        
        let verify = try JSONDecoder().decode(MobileVerifyResponse.self, from: data)
        
        return verify
    }
    
    func exchangeCodeForToken(baseURL: URL, clientId: String, clientSecret: String, code: String) async throws -> OAuthTokenResponse {
        guard let tokenURL = URL(string: "login/oauth2/token", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code
        ]
        
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Token exchange error: \(errorData)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Token exchange raw response: \(jsonString)")
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        return tokenResponse
    }
}

