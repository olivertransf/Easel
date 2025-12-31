//
//  EaselApp.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

@main
struct EaselApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if url.scheme == "easel" {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OAuthCallback"),
                            object: nil,
                            userInfo: ["url": url]
                        )
                    }
                }
        }
    }
}
