//
//  ContentView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginService = LoginService()
    
    var body: some View {
        Group {
            if loginService.isAuthenticated, let session = loginService.currentSession {
                HomeView(loginService: loginService, session: session)
            } else {
                LoginStartView(loginService: loginService)
            }
        }
    }
}

#Preview("Login") {
    ContentView()
}
