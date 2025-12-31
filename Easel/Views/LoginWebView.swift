import SwiftUI
import WebKit

struct LoginWebView: UIViewControllerRepresentable {
    let host: String
    let authenticationProvider: String?
    let loginService: LoginService
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = LoginWebViewController()
        controller.host = host
        controller.authenticationProvider = authenticationProvider
        controller.loginService = loginService
        controller.onDismiss = {
            dismiss()
        }
        controller.onLoginComplete = { session in
            loginService.userDidLogin(session: session)
            dismiss()
        }
        
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

class LoginWebViewController: UIViewController {
    var host = ""
    var authenticationProvider: String?
    weak var loginService: LoginService?
    var onDismiss: (() -> Void)?
    var onLoginComplete: ((LoginSession) -> Void)?
    
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var mobileVerify: MobileVerifyResponse?
    private let verifyService = MobileVerifyService()
    private var task: Task<Void, Never>?
    private var loadObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        title = host
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        setupWebView()
        setupProgressView()
        
        task = Task {
            await loadMobileVerify()
        }
    }
    
    deinit {
        task?.cancel()
        loadObservation?.invalidate()
    }
    
    @objc private func cancelTapped() {
        if let navController = navigationController {
            navController.popViewController(animated: true)
        } else {
            onDismiss?()
        }
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .systemBackground
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.progress = 0
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        loadObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
            guard let self = self, let progressView = self.progressView else { return }
            let newValue = Float(webView.estimatedProgress)
            progressView.setProgress(newValue, animated: newValue >= progressView.progress)
            guard newValue >= 1 else { return }
            UIView.animate(withDuration: 0.3) {
                progressView.alpha = 0
            } completion: { _ in
                progressView.isHidden = true
            }
        }
    }
    
    private func loadMobileVerify() async {
        print("LoginWebView: Loading mobile verify for domain: '\(host)'")
        
        do {
            mobileVerify = try await verifyService.getMobileVerify(domain: host)
            
            await MainActor.run {
                loadLoginWebRequest()
            }
        } catch {
            await MainActor.run {
                let message: String
                if case APIError.invalidResponse = error {
                    message = "Go back and make sure you entered a valid institution name."
                } else {
                    message = "Failed to connect to Canvas: \(error.localizedDescription)"
                }
                showError(message)
            }
        }
    }
    
    private func loadLoginWebRequest() {
        guard let verify = mobileVerify,
              let baseURL = verify.baseURL,
              let clientID = verify.clientId else {
            showError("Go back and make sure you entered a valid institution name.")
            return
        }
        
        guard var components = URLComponents(string: "/login/oauth2/auth") else {
            showError("Failed to create login URL")
            return
        }
        
        var queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: "https://canvas/login"),
            URLQueryItem(name: "mobile", value: "1")
        ]
        
        if let provider = authenticationProvider {
            queryItems.append(URLQueryItem(name: "authentication_provider", value: provider))
        }
        
        components.queryItems = queryItems
        
        guard let finalURL = components.url(relativeTo: baseURL) else {
            showError("Failed to create login URL")
            return
        }
        
        var request = URLRequest(url: finalURL)
        request.timeoutInterval = 30
        webView.load(request)
    }
    
    private func handleOAuthCallback(code: String) async {
        guard let mobileVerify = mobileVerify,
              let baseURL = mobileVerify.baseURL,
              let clientId = mobileVerify.clientId,
              let clientSecret = mobileVerify.clientSecret else {
            await MainActor.run {
                showError("Missing OAuth credentials")
            }
            return
        }
        
        do {
            let tokenResponse = try await verifyService.exchangeCodeForToken(
                baseURL: baseURL,
                clientId: clientId,
                clientSecret: clientSecret,
                code: code
            )
            
            await MainActor.run {
                let session = LoginSession(
                    accessToken: tokenResponse.access_token,
                    baseURL: baseURL,
                    expiresAt: tokenResponse.expires_in.map { Date().addingTimeInterval($0) },
                    locale: tokenResponse.user.effective_locale,
                    refreshToken: tokenResponse.refresh_token,
                    userID: tokenResponse.user.id,
                    userName: tokenResponse.user.name,
                    userEmail: tokenResponse.user.email,
                    clientID: clientId,
                    clientSecret: clientSecret,
                    canvasRegion: tokenResponse.canvas_region
                )
                
                onLoginComplete?(session)
            }
        } catch {
            await MainActor.run {
                showError("Failed to complete login: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LoginWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return decisionHandler(.allow)
        }
        
        if components.scheme == "about" && components.path == "blank" {
            return decisionHandler(.cancel)
        }
        
        let queryItems = components.queryItems
        if url.absoluteString.hasPrefix("https://canvas/login"),
           let code = queryItems?.first(where: { $0.name == "code" })?.value,
           !code.isEmpty,
           let mobileVerify = mobileVerify,
           mobileVerify.baseURL != nil {
            task?.cancel()
            Task {
                await handleOAuthCallback(code: code)
            }
            return decisionHandler(.cancel)
        } else if queryItems?.first(where: { $0.name == "error" })?.value == "access_denied" {
            showError("Authentication failed. Most likely the user denied the request for access.")
            return decisionHandler(.cancel)
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.alpha = 1
        progressView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if !error.isFrameLoadInterrupted {
            if nsError.code == NSURLErrorTimedOut {
                showError("We received no response from the institution.\nGo back and make sure you entered a valid institution name.")
            } else {
                showError("Failed to load login page: \(error.localizedDescription)")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
}

extension Error {
    var isFrameLoadInterrupted: Bool {
        let nsError = self as NSError
        return nsError.domain == "WebKitErrorDomain" && nsError.code == 102
    }
}

