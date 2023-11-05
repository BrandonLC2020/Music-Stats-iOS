//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI


struct AccessTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
    let expires_in: Int
    let refresh_token: String
}

struct TabUIView: View {
    var accessToken: String
    var tokenType: String
    var refreshToken: String? = UserDefaults.standard.object(forKey: "refreshToken") as? String
    var userTopItems: UserTopItems = UserTopItems()

    
    init(code: String) {
        self.accessToken = ""
        self.tokenType = ""
        getTokens(code: code)
        userTopItems = UserTopItems(access: self.accessToken, token: self.tokenType)
    }
    
    func getTokensURL() -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/api/token"
        return components.string!
    }
    
    mutating func getTokens(code: String) {
        var urlRequest = URLRequest(url: URL(string: getTokensURL())!)
        let combo = "\(SPOTIFY_API_CLIENT_ID):\(SPOTIFY_API_CLIENT_SECRET)"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = ["Authorization" : "Bearer \(comboEncoded!)", "Content-Type" : "application/x-www-form-urlencoded"]
        
        let redirectURI = "https://www.google.com"
        let grantType = "authorization_code"
        var components = URLComponents()
        print("code is \(code)")
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: grantType),
        ]
        urlRequest.httpBody = components.query?.data(using: .utf8)
        
        var tempAccessToken = ""
        var tempTokenType = ""
        var tempRefreshToken = ""
        print(urlRequest)
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    print("Invalid login!")
                    return
                } else if httpResponse.statusCode == 500 {
                    print("Database failure!")
                    return
                }
            }
            
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                print(data)
                let string = String(data: data, encoding: .utf8)
                print(string)
                let ret: AccessTokenResponse = try! JSONDecoder().decode(AccessTokenResponse.self, from: data)
                print("ret")
                print(ret)
                tempAccessToken = ret.access_token
                tempTokenType = ret.token_type
                tempRefreshToken = ret.refresh_token
            } else {
                print("Unexpected error!")
            }

        }.resume()
        print("tempAccessToken is \(tempAccessToken)")
        self.accessToken = tempAccessToken
        self.tokenType = tempTokenType
        self.refreshToken = tempRefreshToken
        UserDefaults.standard.set(self.refreshToken, forKey: "refreshToken")
    }
    
    var body: some View {
        TabView {
            TopSongsView(topSongs: userTopItems.topSongsList)
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Top Songs")
                }
        }.accentColor(.black)
    }
}

#Preview {
    TabUIView(code: UserDefaults.standard.object(forKey: "code") as! String)
}
