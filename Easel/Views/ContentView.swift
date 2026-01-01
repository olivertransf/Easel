//
//  ContentView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import Inject

struct ContentView: View {
    @ObserveInjection var iO
    @StateObject private var loginService = LoginService()
    
    var body: some View {
        Group {
            if loginService.isAuthenticated, let session = loginService.currentSession {
                HomeView(loginService: loginService, session: session)
            } else {
                LoginStartView(loginService: loginService)
            }
        }
        .enableInjection()
    }
}

#Preview("Login") {
    ContentView()
}
