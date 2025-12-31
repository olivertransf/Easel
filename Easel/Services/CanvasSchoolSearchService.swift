import Foundation

class CanvasSchoolSearchService {
    private let searchURL = "https://canvas.instructure.com/api/v1/accounts/search"
    
    func searchSchools(query: String) async throws -> [CanvasAccount] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "search_term", value: query)
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let accounts = try JSONDecoder().decode([CanvasAccount].self, from: data)
        return accounts
    }
}

