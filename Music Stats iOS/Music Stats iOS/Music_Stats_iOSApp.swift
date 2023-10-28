//
//  Music_Stats_iOSApp.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import SwiftUI
import Foundation

let SPOTIFY_API_CLIENT_ID = "3c71d3fa96a74c1999184c5690f507d9"
let SPOTIFY_API_CLIENT_SECRET = "fe3b975ee9b4499f9d72a9bddd5b3c86"

struct AuthorizationResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

@main
struct Music_Stats_iOSApp: App {
    
    var userTopItems : UserTopItems = UserTopItems()
    var accessToken : String
    var tokenType : String
    
    init() {
        self.accessToken = ""
        self.tokenType = ""
        refreshAccessAndRefreshTokens()
        self.userTopItems = UserTopItems(access: self.accessToken, token: self.tokenType)
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
        //request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        //let bodyParams = "grant_type=client_credentials&client_id=\(SPOTIFY_API_CLIENT_ID)&client_secret=\(SPOTIFY_API_CLIENT_SECRET)"
        //request.httpBody = bodyParams.data(using: String.Encoding.ascii, allowLossyConversion: true)
//        var access_token:String = ""
//        var token_type:String = ""
        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            do {
                print(String(data: data, encoding: String.Encoding.utf8)!)
                let responseObject = try JSONDecoder().decode([String:String].self, from: data)
                print(responseObject)
//                access_token = responseObject.access_token
//                token_type = responseObject.token_type
            } catch {
                print(error) // parsing error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }.resume()
        //print("access token is \(access_token)")
//        self.accessToken = access_token
//        self.tokenType = token_type
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                TabUIView(topSongs: userTopItems.topSongsList)
            }
            
        }
    }
}

class UserTopItems: ObservableObject {
    @Published var topSongsResponse: [String : [SongResponse]]
    @Published var topArtistsResponse: [String : [ArtistResponse]]
    @Published var topSongsList: [String : [Song]]
    @Published var topArtistsList: [String : [Artist]]
    var accessToken: String
    var tokenType: String
    
    init() {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.accessToken = ""
        self.tokenType = ""
    }
    
    init(access: String, token: String) {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.accessToken = access
        self.tokenType = token
        getTopSongs()
        getTopArtists()
        
        print(topSongsList)
    }
    
    func getTopSongs() {
        let first50SongsResponseShortTerm = getSongsForTimeRange(range: "short_term", offset: 0)
        let next50SongsResponseShortTerm = getSongsForTimeRange(range: "short_term", offset: 50)
        
        let first50SongsResponseMediumTerm = getSongsForTimeRange(range: "medium_term", offset: 0)
        let next50SongsResponseMediumTerm = getSongsForTimeRange(range: "medium_term", offset: 50)
        
        let first50SongsResponseLongTerm = getSongsForTimeRange(range: "long_term", offset: 0)
        let next50SongsResponseLongTerm = getSongsForTimeRange(range: "long_term", offset: 50)
        
        let top100SongsShortTerm = first50SongsResponseShortTerm.items + next50SongsResponseShortTerm.items
        let top100SongsMediumTerm = first50SongsResponseMediumTerm.items + next50SongsResponseMediumTerm.items
        let top100SongsLongTerm = first50SongsResponseLongTerm.items + next50SongsResponseLongTerm.items
        
        self.topSongsResponse = ["short" : top100SongsShortTerm, "medium" : top100SongsMediumTerm, "long" : top100SongsLongTerm]
        
        self.topSongsList["short"] = []
        for i in 0...self.topSongsResponse["short"]!.endIndex {
            let album: Album = Album(images: self.topSongsResponse["short"]![i].album.images, name: self.topSongsResponse["short"]![i].album.name, release_date: self.topSongsResponse["short"]![i].album.release_date)
            var artist: [Artist] = []
            for art in self.topSongsResponse["short"]![i].artists {
                artist.append(Artist(name: art.name, artistId: art.id))
            }
            self.topSongsList["short"]?.append(Song(rank: i+1, album: album, artists: artist, duration_ms: self.topSongsResponse["short"]![i].duration_ms, name: self.topSongsResponse["short"]![i].name, popularity: self.topSongsResponse["short"]![i].popularity))
        }
        self.topSongsList["medium"] = []
        for i in 0...self.topSongsResponse["medium"]!.endIndex {
            let album: Album = Album(images: self.topSongsResponse["medium"]![i].album.images, name: self.topSongsResponse["medium"]![i].album.name, release_date: self.topSongsResponse["medium"]![i].album.release_date)
            var artist: [Artist] = []
            for art in self.topSongsResponse["medium"]![i].artists {
                artist.append(Artist(name: art.name, artistId: art.id))
            }
            self.topSongsList["medium"]?.append(Song(rank: i+1, album: album, artists: artist, duration_ms: self.topSongsResponse["medium"]![i].duration_ms, name: self.topSongsResponse["medium"]![i].name, popularity: self.topSongsResponse["medium"]![i].popularity))
        }
        self.topSongsList["long"] = []
        for i in 0...self.topSongsResponse["long"]!.endIndex {
            let album: Album = Album(images: self.topSongsResponse["long"]![i].album.images, name: self.topSongsResponse["long"]![i].album.name, release_date: self.topSongsResponse["long"]![i].album.release_date)
            var artist: [Artist] = []
            for art in self.topSongsResponse["long"]![i].artists {
                artist.append(Artist(name: art.name, artistId: art.id))
            }
            self.topSongsList["long"]?.append(Song(rank: i+1, album: album, artists: artist, duration_ms: self.topSongsResponse["long"]![i].duration_ms, name: self.topSongsResponse["long"]![i].name, popularity: self.topSongsResponse["long"]![i].popularity))
        }
    }
    
    func getTopArtists() {
        let first50ArtistsResponseShortTerm = getArtistsForTimeRange(range: "short_term", offset: 0)
        let next50ArtistsResponseShortTerm = getArtistsForTimeRange(range: "short_term", offset: 50)
        
        let first50ArtistsResponseMediumTerm = getArtistsForTimeRange(range: "medium_term", offset: 0)
        let next50ArtistsResponseMediumTerm = getArtistsForTimeRange(range: "medium_term", offset: 50)
        
        let first50ArtistsResponseLongTerm = getArtistsForTimeRange(range: "long_term", offset: 0)
        let next50ArtistsResponseLongTerm = getArtistsForTimeRange(range: "long_term", offset: 50)
        
        let top100ArtistsShortTerm = first50ArtistsResponseShortTerm.items + next50ArtistsResponseShortTerm.items
        let top100ArtistsMediumTerm = first50ArtistsResponseMediumTerm.items + next50ArtistsResponseMediumTerm.items
        let top100ArtistsLongTerm = first50ArtistsResponseLongTerm.items + next50ArtistsResponseLongTerm.items
        
        self.topArtistsResponse = ["short" : top100ArtistsShortTerm, "medium" : top100ArtistsMediumTerm, "long" : top100ArtistsLongTerm]
        
        self.topArtistsList["short"] = []
        for i in 0...self.topArtistsResponse["short"]!.endIndex {
            self.topArtistsList["short"]?.append(Artist(rank: i+1, images: self.topArtistsResponse["short"]![i].images, name: self.topArtistsResponse["short"]![i].name, popularity: self.topArtistsResponse["short"]![i].popularity, artistId: self.topArtistsResponse["short"]![i].id))
        }
        self.topArtistsList["medium"] = []
        for i in 0...self.topArtistsResponse["medium"]!.endIndex {
            self.topArtistsList["medium"]?.append(Artist(rank: i+1, images: self.topArtistsResponse["medium"]![i].images, name: self.topArtistsResponse["medium"]![i].name, popularity: self.topArtistsResponse["medium"]![i].popularity, artistId: self.topArtistsResponse["medium"]![i].id))
        }
        self.topArtistsList["long"] = []
        for i in 0...self.topArtistsResponse["long"]!.endIndex {
            self.topArtistsList["long"]?.append(Artist(rank: i+1, images: self.topArtistsResponse["long"]![i].images, name: self.topArtistsResponse["long"]![i].name, popularity: self.topArtistsResponse["long"]![i].popularity, artistId: self.topArtistsResponse["long"]![i].id))
        }
    }
    
    func getSongsForTimeRange(range: String, offset: Int) -> TopSongsResponse {
        var result: TopSongsResponse = TopSongsResponse(href: "", limit: 0, offset: 0, total: 0, items: [])

        let urlStr = "https://api.spotify.com/v1/me/top/tracks?time_range=\(range)&limit=50&offset=\(String(offset))"
        let authorizationAccessTokenStr = accessToken
        let authorizationTokenTypeStr = tokenType
        let requestHeaders: [String:String] = ["Authorization" : "\(authorizationTokenTypeStr) \(authorizationAccessTokenStr)"]
        //print(requestHeaders)
        var request = URLRequest(url: URL(string: urlStr)!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            do {
                //print(data)
                let responseObject: TopSongsResponse = try JSONDecoder().decode(TopSongsResponse.self, from: data)
                //print(responseObject)
                result = responseObject
            } catch {
                print(error) // parsing error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }.resume()
        //print(result)
        return result
    }
    
    func getArtistsForTimeRange(range: String, offset: Int) -> TopArtistsResponse {
        var result: TopArtistsResponse = TopArtistsResponse(href: "", limit: 0, offset: 0, total: 0, items: [])
        
        let urlStr = "https://api.spotify.com/v1/me/top/artists?time_range=" + range + "&limit=50&offset=" + String(offset)
        let authorizationAccessTokenStr = UserDefaults.standard.object(forKey: "access_token") as! String
        let authorizationTokenTypeStr = UserDefaults.standard.object(forKey: "token_type") as! String
        let requestHeaders: [String:String] = ["Authorization" : authorizationTokenTypeStr + " " + authorizationAccessTokenStr]
        var request = URLRequest(url: URL(string: urlStr)!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            do {
                let responseObject: TopArtistsResponse = try JSONDecoder().decode(TopArtistsResponse.self, from: data)
                result = responseObject
            } catch {
                print(error) // parsing error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }.resume()
        print(result)
        return result
    }
    
}

