import Foundation

struct CanvasFile: Codable {
    let id: String
    let displayName: String
    let filename: String
    let contentType: String
    let url: URL?
    let size: Int?
    let mimeClass: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case filename
        case contentType = "content-type"
        case url
        case size
        case mimeClass = "mime_class"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        displayName = try container.decode(String.self, forKey: .displayName)
        filename = try container.decode(String.self, forKey: .filename)
        contentType = try container.decode(String.self, forKey: .contentType)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        size = try container.decodeIfPresent(Int.self, forKey: .size)
        mimeClass = try container.decode(String.self, forKey: .mimeClass)
    }
}

