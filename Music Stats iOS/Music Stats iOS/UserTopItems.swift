//
//  UserTopItems.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import Foundation


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
    
    func getTopSongs(completion: @escaping () -> Void) {
        let ranges = ["short_term", "medium_term", "long_term"]
        let group = DispatchGroup()
        
        for range in ranges {
            let key = range.components(separatedBy: "_")[0]
            group.enter()
            getSongsForTimeRange(range: range, offset: 0) { songsResponse in
                if let songsResponse = songsResponse {
                    DispatchQueue.main.async {
                        self.topSongsResponse[key] = songsResponse.items
                        
                        self.topSongsList[key] = songsResponse.items.enumerated().map { (index, songResponse) in
                            let album = Album(images: songResponse.album.images, name: songResponse.album.name, release_date: songResponse.album.release_date)
                            let artists = songResponse.artists.map { Artist(name: $0.name, artistId: $0.id) }
                            return Song(rank: index + 1, album: album, artists: artists, duration_ms: songResponse.duration_ms, name: songResponse.name, popularity: songResponse.popularity)
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func getTopArtists(completion: @escaping () -> Void) {
        let ranges = ["short_term", "medium_term", "long_term"]
        let group = DispatchGroup()
        
        for range in ranges {
            let key = range.components(separatedBy: "_")[0]
            group.enter()
            getArtistsForTimeRange(range: range, offset: 0) { artistsResponse in
                if let artistsResponse = artistsResponse {
                    DispatchQueue.main.async {
                        self.topArtistsResponse[key] = artistsResponse.items
                        
                        self.topArtistsList[key] = artistsResponse.items.enumerated().map { (index, artistResponse) in
                            return Artist(rank: index + 1, images: artistResponse.images, name: artistResponse.name, popularity: artistResponse.popularity, artistId: artistResponse.id)
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func getSongsForTimeRange(range: String, offset: Int, userCompletionHandler: @escaping (TopSongsResponse?) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/tracks"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = components.url else {
            userCompletionHandler(nil)
            return
        }
        
        let authorizationAccessTokenStr = accessToken
        let authorizationTokenTypeStr = tokenType
        let requestHeaders: [String:String] = ["Authorization" : "\(authorizationTokenTypeStr) \(authorizationAccessTokenStr)"]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                userCompletionHandler(nil)
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                userCompletionHandler(nil)
                return
            }
            do {
                let responseObject: TopSongsResponse = try JSONDecoder().decode(TopSongsResponse.self, from: data)
                userCompletionHandler(responseObject)
                
            } catch {
                print(error) // parsing error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
                userCompletionHandler(nil)
            }
        }).resume()
    }
    
    func getArtistsForTimeRange(range: String, offset: Int, userCompletionHandler: @escaping (TopArtistsResponse?) -> Void) {
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/artists"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = components.url else {
            userCompletionHandler(nil)
            return
        }

        let authorizationAccessTokenStr = accessToken
        let authorizationTokenTypeStr = tokenType
        let requestHeaders: [String:String] = ["Authorization" : authorizationTokenTypeStr + " " + authorizationAccessTokenStr]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                userCompletionHandler(nil)
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                userCompletionHandler(nil)
                return
            }
            do {
                let responseObject: TopArtistsResponse = try JSONDecoder().decode(TopArtistsResponse.self, from: data)
                userCompletionHandler(responseObject)
            } catch {
                print(error) // parsing error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
                userCompletionHandler(nil)
            }
        }).resume()
    }
    
}
