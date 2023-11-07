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
    @State var accessToken: String
    @State var tokenType: String
    @State var refreshToken: String? = UserDefaults.standard.object(forKey: "refreshToken") as? String
    @State var userTopItems: UserTopItems = UserTopItems()

    init() {
        self.accessToken = ""
        self.tokenType = ""
    }
    
    init(code: String) {
        self.accessToken = ""
        self.tokenType = ""
        var accessResults: [String] = []
        getTokens(code: code, userCompletionHandler: { user in
            if let user = user {
                accessResults = user
            }
            
        })
        while (accessResults.isEmpty) {}
        self.accessToken = accessResults[0]
        self.tokenType = accessResults[1] 
        self.refreshToken = accessResults[2]
        userTopItems = UserTopItems(access: self.accessToken, token: self.tokenType)
    }
    
    func getTokensURL() -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"
        return components.string!
    }
    
    func getTokens(code: String, userCompletionHandler: @escaping ([String]?) -> Void) {
        var urlRequest = URLRequest(url: URL(string: getTokensURL())!)
        let combo = "\(SPOTIFY_API_CLIENT_ID):\(SPOTIFY_API_CLIENT_SECRET)"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = ["Authorization" : "Basic \(comboEncoded!)", "Content-Type" : "application/x-www-form-urlencoded"]
        
        let redirectURI = "https://www.google.com"
        let grantType = "authorization_code"
        var components = URLComponents()
        //print("code is \(code)")
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
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            //print("this got called")
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    print("Invalid login!")
                    return
                } else if httpResponse.statusCode == 500 {
                    print("Database failure!")
                    return
                } else if httpResponse.statusCode == 401 {
                    print("invalid access token")
                    return
                }
            }
            
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                //print("made it inn here")
                //print(data)
                let string = String(data: data, encoding: .utf8)
                //print("string is \(string ?? "empty")")
                let ret: AccessTokenResponse = try! JSONDecoder().decode(AccessTokenResponse.self, from: data)
//                print("ret")
//                print(ret)
//                print(ret.access_token)
//                self.accessToken = ret.access_token
//                self.tokenType = ret.token_type
//                self.refreshToken = ret.refresh_token
                userCompletionHandler([ret.access_token , ret.token_type , ret.refresh_token])
            } else {
                print("Unexpected error!")
            }

        }).resume()
//        print("tempAccessToken is \(tempAccessToken)")
//        self.accessToken = tempAccessToken
//        self.tokenType = tempTokenType
//        self.refreshToken = tempRefreshToken
        UserDefaults.standard.set(self.refreshToken, forKey: "refreshToken")
    }
    
    var body: some View {
        TabView {
//            TopSongsView(topSongs: userTopItems.topSongsList)
//                .tabItem {
//                    Image(systemName: "music.note")
//                    Text("Top Songs")
//                }
        }.accentColor(.black)
    }
}

//#Preview {
//    TabUIView(code: UserDefaults.standard.object(forKey: "code") as! String)
//}
