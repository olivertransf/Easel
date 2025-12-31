import Foundation
import Combine

@MainActor
class LoginService: ObservableObject {
    @Published var currentSession: LoginSession?
    @Published var isAuthenticated = false
    
    init() {
        loadCurrentSession()
    }
    
    func loadCurrentSession() {
        currentSession = LoginSession.mostRecent
        isAuthenticated = currentSession != nil
    }
    
    func userDidLogin(session: LoginSession) {
        LoginSession.add(session)
        currentSession = session
        isAuthenticated = true
    }
    
    func userDidLogout(session: LoginSession) {
        LoginSession.remove(session)
        if currentSession == session {
            currentSession = nil
            isAuthenticated = false
        }
    }
    
    func logout() {
        if let session = currentSession {
            userDidLogout(session: session)
        }
    }
}

