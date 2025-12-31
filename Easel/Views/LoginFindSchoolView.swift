import SwiftUI

struct LoginFindSchoolView: View {
    @ObservedObject var loginService: LoginService
    @State private var searchText = ""
    @State private var accounts: [CanvasAccount] = []
    @State private var isLoading = false
    @State private var showLogin = false
    @State private var selectedHost = ""
    @State private var selectedProvider: String?
    
    private let searchService = CanvasSchoolSearchService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your school's name?")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Find your school or district", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(.horizontal)
                        .onSubmit {
                            parseInputAndShowLoginScreen()
                        }
                        .onChange(of: searchText) { _, newValue in
                            Task {
                                await search(query: newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                        }
                }
                .padding(.vertical)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if accounts.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("Can't find your school? Try typing the full school URL.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(Array(accounts.enumerated()), id: \.offset) { index, account in
                        Button(action: {
                            print("LoginFindSchoolView: Selected account domain: '\(account.domain)'")
                            selectedHost = account.domain.lowercased()
                            selectedProvider = account.authenticationProvider
                            showLogin = true
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(account.domain)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Find School")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showLogin) {
                LoginWebView(
                    host: selectedHost,
                    authenticationProvider: selectedProvider,
                    loginService: loginService
                )
            }
        }
    }
    
    private func search(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                accounts = []
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let results = try await searchService.searchSchools(query: query)
            await MainActor.run {
                accounts = results
            }
        } catch {
            await MainActor.run {
                accounts = []
            }
        }
    }
    
    private func parseInputAndShowLoginScreen() {
        var host = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        host = extractDomain(from: host)
        
        if !host.contains(".") {
            host = "\(host).instructure.com"
        }
        
        if let account = accounts.first(where: { $0.domain == host }) {
            selectedHost = account.domain
            selectedProvider = account.authenticationProvider
        } else {
            selectedHost = host
            selectedProvider = nil
        }
        
        showLogin = true
    }
    
    private func extractDomain(from input: String) -> String {
        var domain = input
        
        if let url = URL(string: domain) {
            if let host = url.host {
                return host
            }
        }
        
        if domain.hasPrefix("https://") {
            domain = String(domain.dropFirst(8))
        } else if domain.hasPrefix("http://") {
            domain = String(domain.dropFirst(7))
        }
        
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        
        return domain
    }
}

