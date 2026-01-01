//
//  WebViewComponents.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlString: String
    let baseURL: URL
    let session: LoginSession
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 16px;
                    margin: 0;
                    min-height: 100%;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(baseURL: baseURL, session: session)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        var lastHTML: String = ""
        var imageMap: [String: URL] = [:]
        var onImagesLoaded: (([String: URL]) -> Void)?
        
        init(baseURL: URL, session: LoginSession) {
            self.baseURL = baseURL
            self.session = session
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            extractImageURLs(from: webView)
        }
        
        private func extractImageURLs(from webView: WKWebView) {
            let script = """
            (function() {
                var images = document.getElementsByTagName('img');
                var imageMap = {};
                for (var i = 0; i < images.length; i++) {
                    var img = images[i];
                    var src = img.src;
                    if (src && !src.startsWith('data:')) {
                        var imageId = 'img_' + i;
                        img.id = imageId;
                        imageMap[imageId] = src;
                    }
                }
                return imageMap;
            })();
            """
            
            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self,
                      let imageDict = result as? [String: String] else {
                    return
                }
                
                var urlMap: [String: URL] = [:]
                for (imageId, urlString) in imageDict {
                    if let url = URL(string: urlString, relativeTo: self.baseURL) {
                        urlMap[imageId] = url
                    }
                }
                
                self.imageMap = urlMap
                self.onImagesLoaded?(urlMap)
            }
        }
        
        func updateImage(imageId: String, dataURI: String, in webView: WKWebView) {
            let script = """
            (function() {
                var img = document.getElementById('\(imageId)');
                if (img) {
                    img.src = '\(dataURI)';
                }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if url.host == baseURL.host || url.host == nil {
                        decisionHandler(.allow)
                    } else {
                        UIApplication.shared.open(url)
                        decisionHandler(.cancel)
                    }
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct IncrementalImageWebView: UIViewRepresentable {
    let htmlString: String
    let baseURL: URL
    let session: LoginSession
    let courseId: String
    @Binding var navigationPath: NavigationPath
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.navigationPath = $navigationPath
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 16px;
                    margin: 0;
                    min-height: 100%;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            context.coordinator.imageMap = [:]
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> IncrementalImageCoordinator {
        IncrementalImageCoordinator(baseURL: baseURL, session: session, courseId: courseId)
    }
    
    class IncrementalImageCoordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        let courseId: String
        var lastHTML: String = ""
        var imageMap: [String: URL] = [:]
        weak var webView: WKWebView?
        var navigationPath: Binding<NavigationPath>?
        let urlParser: CanvasURLParser
        
        init(baseURL: URL, session: LoginSession, courseId: String) {
            self.baseURL = baseURL
            self.session = session
            self.courseId = courseId
            self.urlParser = CanvasURLParser(baseURL: baseURL, courseId: courseId)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
            extractImageURLs(from: webView)
        }
        
        private func extractImageURLs(from webView: WKWebView) {
            let script = """
            (function() {
                var images = document.getElementsByTagName('img');
                var imageMap = {};
                for (var i = 0; i < images.length; i++) {
                    var img = images[i];
                    var src = img.src;
                    if (src && !src.startsWith('data:')) {
                        var imageId = 'img_' + i;
                        img.id = imageId;
                        imageMap[imageId] = src;
                    }
                }
                return imageMap;
            })();
            """
            
            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self,
                      let imageDict = result as? [String: String] else {
                    return
                }
                
                var urlMap: [String: URL] = [:]
                for (imageId, urlString) in imageDict {
                    if let url = URL(string: urlString, relativeTo: self.baseURL) {
                        urlMap[imageId] = url
                    }
                }
                
                self.imageMap = urlMap
                Task.detached(priority: .userInitiated) {
                    await self.loadImagesIncrementally(imageMap: urlMap)
                }
            }
        }
        
        private func loadImagesIncrementally(imageMap: [String: URL]) async {
            await withTaskGroup(of: (String, String)?.self) { group in
                for (imageId, imageURL) in imageMap {
                    group.addTask {
                        if let dataURI = await self.downloadImageAsDataURI(url: imageURL) {
                            return (imageId, dataURI)
                        }
                        return nil
                    }
                }
                
                for await result in group {
                    if let (imageId, dataURI) = result {
                        await MainActor.run {
                            self.updateImage(imageId: imageId, dataURI: dataURI)
                        }
                    }
                }
            }
        }
        
        private func downloadImageAsDataURI(url: URL) async -> String? {
            let absoluteURL = url.absoluteURL.standardized
            
            var request = URLRequest(url: absoluteURL)
            if let token = session.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    return nil
                }
                
                let mimeType = httpResponse.mimeType ?? "image/png"
                let base64 = data.base64EncodedString()
                return "data:\(mimeType);base64,\(base64)"
            } catch {
                print("Failed to download image \(url.absoluteString): \(error)")
                return nil
            }
        }
        
        private func updateImage(imageId: String, dataURI: String) {
            guard let webView = webView else { return }
            let escapedDataURI = dataURI.replacingOccurrences(of: "'", with: "\\'")
            let script = """
            (function() {
                var img = document.getElementById('\(imageId)');
                if (img) {
                    img.src = '\(escapedDataURI)';
                }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    print("Link clicked: \(url.absoluteString)")
                    if let destination = urlParser.parse(url: url) {
                        print("Parsed destination: \(destination)")
                        decisionHandler(.cancel)
                        DispatchQueue.main.async {
                            print("=== APPENDING TO NAVIGATION PATH ===")
                            print("Navigation path count before append: \(self.navigationPath?.wrappedValue.count ?? -1)")
                            self.navigationPath?.wrappedValue.append(destination)
                            print("Navigation path count after append: \(self.navigationPath?.wrappedValue.count ?? -1)")
                            print("====================================")
                        }
                        return
                    } else {
                        print("Could not parse URL: \(url.absoluteString)")
                    }
                    
                    if url.host == baseURL.host || url.host == nil {
                        decisionHandler(.allow)
                    } else {
                        UIApplication.shared.open(url)
                        decisionHandler(.cancel)
                    }
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct ModuleItemWebView: UIViewRepresentable {
    let url: URL
    let baseURL: URL
    let session: LoginSession
    let title: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.ensureLoaded(webView: webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.originalURL != url {
            context.coordinator.originalURL = url
            context.coordinator.loadWebSession(webView: webView)
        } else if context.coordinator.needsInitialLoad {
            context.coordinator.needsInitialLoad = false
            context.coordinator.loadWebSession(webView: webView)
        }
    }
    
    func makeCoordinator() -> ModuleItemWebViewCoordinator {
        ModuleItemWebViewCoordinator(baseURL: baseURL, session: session, originalURL: url)
    }
    
    class ModuleItemWebViewCoordinator: NSObject, WKNavigationDelegate {
        let baseURL: URL
        let session: LoginSession
        var originalURL: URL
        var needsInitialLoad = true
        
        init(baseURL: URL, session: LoginSession, originalURL: URL) {
            self.baseURL = baseURL
            self.session = session
            self.originalURL = originalURL
        }
        
        func ensureLoaded(webView: WKWebView) {
            if needsInitialLoad {
                needsInitialLoad = false
                DispatchQueue.main.async {
                    self.loadWebSession(webView: webView)
                }
            }
        }
        
        func loadWebSession(webView: WKWebView) {
            Task {
                do {
                    let apiService = CanvasAPIService(session: session)
                    let sessionURL = try await apiService.getWebSession(to: originalURL)
                    
                    await MainActor.run {
                        let request = URLRequest(url: sessionURL)
                        webView.load(request)
                    }
                } catch {
                    print("Failed to get web session: \(error)")
                    await MainActor.run {
                        let request = URLRequest(url: originalURL)
                        webView.load(request)
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct ModuleItemFileView: UIViewRepresentable {
    let fileId: String?
    let courseId: String?
    let url: URL?
    let baseURL: URL
    let session: LoginSession
    let title: String
    
    init(fileId: String, courseId: String, baseURL: URL, session: LoginSession, title: String) {
        self.fileId = fileId
        self.courseId = courseId
        self.url = nil
        self.baseURL = baseURL
        self.session = session
        self.title = title
    }
    
    init(url: URL, baseURL: URL, session: LoginSession, title: String) {
        self.fileId = nil
        self.courseId = nil
        self.url = url
        self.baseURL = baseURL
        self.session = session
        self.title = title
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.ensureLoaded(webView: webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let currentURL = url ?? context.coordinator.fileURL
        if let currentURL = currentURL, context.coordinator.originalURL != currentURL {
            context.coordinator.originalURL = currentURL
            context.coordinator.loadFile(webView: webView)
        } else if context.coordinator.needsInitialLoad {
            context.coordinator.needsInitialLoad = false
            context.coordinator.loadFile(webView: webView)
        }
    }
    
    func makeCoordinator() -> ModuleItemFileViewCoordinator {
        ModuleItemFileViewCoordinator(fileId: fileId, courseId: courseId, url: url, baseURL: baseURL, session: session)
    }
    
    class ModuleItemFileViewCoordinator: NSObject, WKNavigationDelegate {
        let fileId: String?
        let courseId: String?
        var url: URL?
        let baseURL: URL
        let session: LoginSession
        var originalURL: URL?
        var fileURL: URL?
        var needsInitialLoad = true
        
        init(fileId: String?, courseId: String?, url: URL?, baseURL: URL, session: LoginSession) {
            self.fileId = fileId
            self.courseId = courseId
            self.url = url
            self.baseURL = baseURL
            self.session = session
        }
        
        func ensureLoaded(webView: WKWebView) {
            if needsInitialLoad {
                needsInitialLoad = false
                DispatchQueue.main.async {
                    self.loadFile(webView: webView)
                }
            }
        }
        
        func loadFile(webView: WKWebView) {
            Task {
                var targetURL: URL?
                
                if let fileId = fileId, let courseId = courseId {
                    do {
                        let apiService = CanvasAPIService(session: session)
                        let file = try await apiService.getFile(courseId: courseId, fileId: fileId)
                        if let fileDownloadURL = file.url {
                            targetURL = fileDownloadURL
                            self.fileURL = fileDownloadURL
                        } else {
                            let fileDownloadURL = baseURL.appendingPathComponent("api/v1/courses/\(courseId)/files/\(fileId)/download")
                            targetURL = fileDownloadURL
                            self.fileURL = fileDownloadURL
                        }
                    } catch {
                        let fileDownloadURL = baseURL.appendingPathComponent("api/v1/courses/\(courseId)/files/\(fileId)/download")
                        targetURL = fileDownloadURL
                        self.fileURL = fileDownloadURL
                    }
                } else if let url = url {
                    if url.pathComponents.contains("files") && !url.pathComponents.contains("download") {
                        targetURL = url.appendingPathComponent("download")
                        fileURL = targetURL
                    } else {
                        targetURL = url
                        fileURL = url
                    }
                }
                
                guard let targetURL = targetURL else { return }
                originalURL = targetURL
                
                await MainActor.run {
                    var request = URLRequest(url: targetURL)
                    if let token = session.accessToken {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    request.setValue("application/json+canvas-string-ids", forHTTPHeaderField: "Accept")
                    webView.load(request)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

