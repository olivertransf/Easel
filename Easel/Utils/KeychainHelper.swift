//
//  KeychainHelper.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

class KeychainHelper {
    static let serviceName = Bundle.main.bundleIdentifier ?? "com.olivertran.Easel"
    
    @discardableResult
    static func setData(_ data: Data, for key: String) -> Bool {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key
        ]
        
        let exists = SecItemCopyMatching(query as CFDictionary, nil) == noErr
        var status: OSStatus?
        
        if exists {
            status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        } else {
            query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            query[kSecValueData] = data
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        return status == errSecSuccess
    }
    
    @discardableResult
    static func setJSON<T: Encodable>(_ value: T, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return setData(data, for: key)
    }
    
    static func getData(for key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == noErr {
            return result as? Data
        }
        return nil
    }
    
    static func getJSON<T: Decodable>(for key: String) -> T? {
        guard let data = getData(for: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    @discardableResult
    static func delete(key: String, service: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    static func save(key: String, data: Data, service: String) {
        _ = setData(data, for: key)
    }
    
    static func load(key: String, service: String) -> Data? {
        return getData(for: key)
    }
}


