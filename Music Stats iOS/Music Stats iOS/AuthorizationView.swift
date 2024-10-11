//
//  AuthorizationView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import SwiftUI
@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    
    // 1
    var url: URL
    @Binding var code: String
    var state: String?
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
    
    func getCode() -> String? {
        return self.code
    }
    
    func getCodeFromURL(urlString: String) -> String? {
        if let urlComponent = URLComponents(string: urlString) {
            // queryItems is an array of "key name" and "value"
            let queryItems = urlComponent.queryItems
            // to find "success" value, we need to find based on key name
            let codeValue = queryItems?.first(where: { $0.name == "code" })?.value
            // result is optional
            if codeValue == nil {
                print("Key code not found")
            }
            else {
                // tadaa, here is the key value
                //print("Value of code: \(codeValue!)")
            }
            return codeValue
        }
        return nil
    }
    
    func getStateFromURL(urlString: String) -> String? {
        if let urlComponent = URLComponents(string: urlString) {
            // queryItems is an array of "key name" and "value"
            let queryItems = urlComponent.queryItems
            // to find "success" value, we need to find based on key name
            let stateValue = queryItems?.first(where: { $0.name == "state" })?.value
            // result is optional
            if stateValue == nil {
                print("Key state not found")
            }
            else {
                // tadaa, here is the key value
                //print("Value of state: \(stateValue!)")
            }
            return stateValue
        }
        return nil
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
                    let code = parent.getCodeFromURL(urlString: navigationAction.request.url!.absoluteString)
                    //print("return code is \(code ?? "EMPTY")")
                    //print(navigationAction.request.url!.absoluteString)
                    let state = parent.getStateFromURL(urlString: navigationAction.request.url!.absoluteString)
                    parent.code = code!
                    UserDefaults.standard.set(code, forKey: "code")
                    parent.state = state
                    parent.showWebView = false
                    //print("completed")
                    //print(parent.code)
                }
                decisionHandler(.allow)
            }
            
        }
    
}


struct AuthorizationView: View {
    // 1
    @State var showWebView: Bool = false
    var urlString: String
    @State var code: String = ""
    @State var tabPage: TabUIView = TabUIView()
    
    
    var body: some View {
        NavigationView {
            VStack {
                Image("Image")
                    .resizable()
                    .cornerRadius(30.0)
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                Button("Authorize") {
                    showWebView = true
                }
                .padding(10)
                .sheet(isPresented: $showWebView) {
                    let webView = WebView(url: URL(string: urlString)!, code: $code, showWebView: $showWebView)
                    webView.onDisappear(perform: {
                        print("this got activated")
                        self.code = webView.getCode()!
                        print("code received is \(self.code)")
                        self.tabPage = TabUIView(code: self.code)
                    })
                }
                NavigationLink("Login", destination: tabPage)
                    .disabled(self.code == "")
            }
        }
    }
}
#Preview {
    AuthorizationView(urlString: "https://accounts.spotify.com/authorize?state=cdd3298e37b276c0&scope=user-read-private%20user-read-email&response_type=code&redirect_uri=https://www.google.com&client_id=3c71d3fa96a74c1999184c5690f507d9")
}

