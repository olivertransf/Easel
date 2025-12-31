//
//  AuthPresentationContextProvider.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationContextProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            // This should rarely happen - if no window scene exists, create a basic window
            // Use deprecated API only as last resort fallback
            return UIWindow()
        }
        
        if #available(iOS 26.0, *) {
            return ASPresentationAnchor(windowScene: windowScene)
        } else {
            if let window = windowScene.windows.first {
                return window
            }
            return UIWindow(windowScene: windowScene)
        }
        #else
        return NSWindow()
        #endif
    }
}


