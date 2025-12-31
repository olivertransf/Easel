//
//  SettingsView.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var loginService: LoginService
    let session: LoginSession
    @State private var currentUser: CanvasUser?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if let user = currentUser {
                    Section {
                        userProfileSection(user: user)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        loginService.userDidLogout(session: session)
                        currentUser = nil
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadUserInfo()
            }
        }
    }
    
    @ViewBuilder
    private func userProfileSection(user: CanvasUser) -> some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Text(user.name.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        
        if let loginId = user.login_id {
            HStack {
                Text("Login ID")
                    .foregroundColor(.secondary)
                Spacer()
                Text(loginId)
                    .fontWeight(.medium)
            }
        }
        
        HStack {
            Text("User ID")
                .foregroundColor(.secondary)
            Spacer()
            Text("\(user.id)")
                .fontWeight(.medium)
        }
    }
    
    private func loadUserInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiService = CanvasAPIService(session: session)
            currentUser = try await apiService.getCurrentUser()
        } catch {
            errorMessage = "Failed to load user info: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}


