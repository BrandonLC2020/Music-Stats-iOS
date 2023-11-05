//
//  Music_Stats_iOSApp.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import SwiftUI
import Foundation
import CryptoKit
import WebKit

let SPOTIFY_API_CLIENT_ID = "3c71d3fa96a74c1999184c5690f507d9"
let SPOTIFY_API_CLIENT_SECRET = "fe3b975ee9b4499f9d72a9bddd5b3c86"

func isLoggedIn() -> Bool {
    let code = UserDefaults.standard.object(forKey: "code") as? String
    if code == nil {
        return false
    }
    return true
}

func generateRandomString(length: Int) -> String {
    // each hexadecimal character represents 4 bits, so we need 2 hex characters per byte
    let byteCount = length / 2
    
    var bytes = [UInt8](repeating: 0, count: byteCount)
    let result = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
    guard result == errSecSuccess else {
        fatalError("Failed to generate random bytes: \(result)")
    }
    
    // convert to hex string
    let hexString = bytes.map { String(format: "%02x", $0) }.joined()
    let paddedHexString = hexString.padding(toLength: length, withPad: "0", startingAt: 0)
    return paddedHexString
}


@main
struct Music_Stats_iOSApp: App {
    
    @State var authenticated: Bool = isLoggedIn()
    var authURL: String = ""
    
    init() {
        self.authURL = getAuthorizationCodeURL()
    }
    
    func getAuthorizationCodeURL() -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"

        let state = generateRandomString(length: 16)
        let scope = "user-read-private user-read-email"
        let clientId = SPOTIFY_API_CLIENT_ID
        let responseType = "code"
        let redirectURI = "https://www.google.com"
        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientId)
        ]
        
        return components.string!
        
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if (!authenticated) {
                    AuthorizationView(urlString: self.authURL)
                } else {
                   TabUIView(code: UserDefaults.standard.object(forKey: "code") as! String)
               }               
            }
        }
    }
}
