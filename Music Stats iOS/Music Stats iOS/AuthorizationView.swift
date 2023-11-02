//
//  AuthorizationView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    // 1
    var url: URL
    @Binding var showWebView: Bool
    // 2
    func makeUIView(context: Context) -> WKWebView {
        let wKWebView = WKWebView()
        wKWebView.navigationDelegate = context.coordinator
        return wKWebView
    }
    
    // 3
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> WebViewCoordinator {
            WebViewCoordinator(self)
        }
        
        class WebViewCoordinator: NSObject, WKNavigationDelegate {
            var parent: WebView
            
            init(_ parent: WebView) {
                self.parent = parent
            }
            //https://www.google.com/?code=AQDXD-Cj9hQfdGEL81Jzyl9zP8t2AuutxRw44D3xo-mz7Zlcvp_7CDcIeYXd8JpY-FMni4NSpikA0P1CQSU0489feHSKzzb6bYz58EXuAhUGhU9OY-JXCKlqc75fojPwJ8FpuRzd20FnHuzr3yNAJICMqMOdxcJUqzv2t1F7mUEc8XoECOlYlkz5SfNZsgznGdGtvfIUspuj0DmF9xY&state=478a062507d3087f
            
            func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
                let urlToMatch = "https://www.google.com/?code="
                if let urlStr = navigationAction.request.url?.absoluteString, urlStr.contains(urlToMatch) {
                    parent.showWebView = false
                }
                decisionHandler(.allow)
            }
            
        }
    
}


struct AuthorizationView: View {
    // 1
    @State var showWebView: Bool = false
    var urlString: String
    
    
    var body: some View {
        Button("Login") {
            // 2
            showWebView = true

        }
        .sheet(isPresented: $showWebView){
            WebView(url: URL(string: urlString)!, showWebView: $showWebView)
        }
    }
}
#Preview {
    AuthorizationView(urlString: "https://accounts.spotify.com/authorize?state=cdd3298e37b276c0&scope=user-read-private%20user-read-email&response_type=code&redirect_uri=https://www.google.com&client_id=3c71d3fa96a74c1999184c5690f507d9")
}

