//
//  AuthManager.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import Foundation
import KeychainSwift

@MainActor
class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    var accessToken: String?
    var tokenType: String?

    private var keychain = KeychainSwift()

    init() {
        if keychain.get("refreshToken") != nil {
            Task { await refreshToken() }
        } else {
            isLoading = false
        }
    }

    func logIn(with code: String) {
        isLoading = true
        Task { await exchangeCodeForTokens(code: code) }
    }

    func logout() {
        accessToken = nil
        tokenType = nil
        keychain.clear()
        isAuthenticated = false
    }

    func refreshToken() async {
        guard let refreshToken = keychain.get("refreshToken") else {
            isAuthenticated = false
            isLoading = false
            return
        }

        let urlRequest = createTokenURLRequest()
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }

    private func createTokenURLRequest() -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let spotifyClientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let spotifyClientSecret = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String
        let combo = "\(spotifyClientID ?? ""):\(spotifyClientSecret ?? "")"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()

        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Basic \(comboEncoded!)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        return urlRequest
    }

    private func performTokenRequest(_ request: URLRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                isAuthenticated = false
                isLoading = false
                return
            }
            if let tokenResponse = try? JSONDecoder().decode(AccessTokenResponse.self, from: data) {
                accessToken = tokenResponse.accessToken
                tokenType = tokenResponse.tokenType
                if let newRefreshToken = tokenResponse.refreshToken {
                    keychain.set(newRefreshToken, forKey: "refreshToken")
                }
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    private func exchangeCodeForTokens(code: String) async {
        let urlRequest = createTokenURLRequest()

        let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }
}
