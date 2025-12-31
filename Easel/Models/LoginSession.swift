import Foundation

struct LoginSession: Codable, Hashable, Identifiable {
    let accessToken: String?
    let baseURL: URL
    let expiresAt: Date?
    let lastUsedAt: Date
    let locale: String?
    let refreshToken: String?
    let userID: String
    let userName: String
    let userEmail: String?
    let clientID: String?
    let clientSecret: String?
    let canvasRegion: String?
    
    var id: String {
        "\(baseURL.host ?? "")-\(userID)"
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case baseURL
        case expiresAt
        case lastUsedAt
        case locale
        case refreshToken
        case userID
        case userName
        case userEmail
        case clientID
        case clientSecret
        case canvasRegion
    }
    
    init(
        accessToken: String? = nil,
        baseURL: URL,
        expiresAt: Date? = nil,
        lastUsedAt: Date = Date(),
        locale: String? = nil,
        refreshToken: String? = nil,
        userID: String,
        userName: String,
        userEmail: String? = nil,
        clientID: String? = nil,
        clientSecret: String? = nil,
        canvasRegion: String? = nil
    ) {
        self.accessToken = accessToken
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = ""
        self.baseURL = components?.url ?? baseURL
        self.expiresAt = expiresAt
        self.lastUsedAt = lastUsedAt
        self.locale = locale
        self.refreshToken = refreshToken
        self.userID = userID
        self.userName = userName
        self.userEmail = userEmail
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.canvasRegion = canvasRegion
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(baseURL)
        hasher.combine(userID)
    }
    
    static func == (lhs: LoginSession, rhs: LoginSession) -> Bool {
        lhs.baseURL == rhs.baseURL && lhs.userID == rhs.userID
    }
    
    func bumpLastUsedAt() -> LoginSession {
        LoginSession(
            accessToken: accessToken,
            baseURL: baseURL,
            expiresAt: expiresAt,
            lastUsedAt: Date(),
            locale: locale,
            refreshToken: refreshToken,
            userID: userID,
            userName: userName,
            userEmail: userEmail,
            clientID: clientID,
            clientSecret: clientSecret,
            canvasRegion: canvasRegion
        )
    }
    
    static var sessions: Set<LoginSession> {
        get { getSessions() }
        set { setSessions(newValue) }
    }
    
    static var mostRecent: LoginSession? {
        sessions.reduce(nil) { (latest, session) -> LoginSession? in
            guard let latest = latest else { return session }
            return latest.lastUsedAt > session.lastUsedAt ? latest : session
        }
    }
    
    static func add(_ session: LoginSession) {
        var sessions = getSessions()
        sessions.remove(session)
        sessions.insert(session)
        setSessions(sessions)
    }
    
    static func remove(_ session: LoginSession) {
        var sessions = getSessions()
        sessions.remove(session)
        setSessions(sessions)
    }
    
    static func clearAll() {
        _ = KeychainHelper.delete(key: Key.users.rawValue, service: KeychainHelper.serviceName)
    }
    
    enum Key: String {
        case users = "CanvasUsers"
    }
    
    private static func getSessions() -> Set<LoginSession> {
        KeychainHelper.getJSON(for: Key.users.rawValue) ?? []
    }
    
    private static func setSessions(_ sessions: Set<LoginSession>) {
        _ = KeychainHelper.setJSON(sessions, for: Key.users.rawValue)
    }
}

