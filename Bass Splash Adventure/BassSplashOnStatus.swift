import WebKit
import Foundation

class BassSplashWebCoordinator: NSObject, WKNavigationDelegate {
    private let callback: (BassSplashWebStatus) -> Void
    private var didStart = false

    init(onStatus: @escaping (BassSplashWebStatus) -> Void) {
        self.callback = onStatus
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !didStart { callback(.progressing(progress: 0.0)) }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        didStart = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        callback(.finished)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        callback(.failure(reason: error.localizedDescription))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        callback(.failure(reason: error.localizedDescription))
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .other && webView.url != nil {
            didStart = true
        }
        decisionHandler(.allow)
    }
}
