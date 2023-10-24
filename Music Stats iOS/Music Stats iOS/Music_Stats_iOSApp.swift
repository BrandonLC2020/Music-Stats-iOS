//
//  Music_Stats_iOSApp.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import SwiftUI

let SPOTIFY_API_CLIENT_ID = "3c71d3fa96a74c1999184c5690f507d9"
let SPOTIFY_API_CLIENT_SECRET = "fe3b975ee9b4499f9d72a9bddd5b3c86"


func isLoggedIn() -> Bool {
    let token = UserDefaults.standard.object(forKey: "accessToken") as? String
    if token == nil {
        return false
    }
    return true
}

@main
struct Music_Stats_iOSApp: App {
    
    @State var authenticated: Bool = isLoggedIn()
    
    init() {
        refreshAccessAndRefreshTokens()
    }
    
    func refreshAccessAndRefreshTokens() {
        let requestHeaders: [String:String] = ["Content-Type" : "application/x-www-form-urlencoded"]
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = [URLQueryItem(name: "grant-type", value: "client_credentials"),
                                            URLQueryItem(name: "client_id", value: SPOTIFY_API_CLIENT_ID),
                                            URLQueryItem(name: "client_secret", value: SPOTIFY_API_CLIENT_SECRET)]
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeaders
        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {                                                               // check for fundamental networking error
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // do whatever you want with the `data`, e.g.:
            
            do {
                let responseObject = try JSONDecoder().decode([String:String].self, from: data)
                print(responseObject)
            } catch {
                print(error) // parsing error
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }.resume()
    }
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
