//
//  AnyCodableValue.swift
//  Easel
//
//  Helper to decode values that can be either Int or String
//

import Foundation

struct AnyCodableValue: Codable {
    let stringValue: String
    
    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            stringValue = string
            return
        }
        
        if let intValue = try? decoder.singleValueContainer().decode(Int.self) {
            stringValue = String(intValue)
            return
        }
        
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Expected String or Int"
        ))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

