//
//  UserTopItems.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import Foundation

class UserTopItems: ObservableObject {
    @Published var topSongsResponse: [String: [SongResponse]]
    @Published var topArtistsResponse: [String: [ArtistResponse]]
    @Published var topSongsList: [String: [Song]]
    @Published var topArtistsList: [String: [Artist]]
    @Published var topAlbumsList: [String: [Album]]
    @Published var userProfile: UserProfile?
    var accessToken: String
    var tokenType: String

    init() {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.topAlbumsList = [:]
        self.userProfile = nil
        self.accessToken = ""
        self.tokenType = ""
    }

    func getUserProfile(completion: @escaping () -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me"

        guard let url = components.url else {
            completion()
            return
        }

        let requestHeaders: [String: String] = ["Authorization": "\(tokenType) \(accessToken)"]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        URLSession.shared.dataTask(with: request) { (data, _, error) in
            guard let data = data, error == nil else {
                completion()
                return
            }

            do {
                let responseObject = try JSONDecoder().decode(UserProfileResponse.self, from: data)
                DispatchQueue.main.async {
                    self.userProfile = UserProfile(
                        id: responseObject.id,
                        displayName: responseObject.displayName,
                        email: responseObject.email,
                        images: responseObject.images
                    )
                    completion()
                }
            } catch {
                print("Error fetching user profile: \(error)")
                completion()
            }
        }.resume()
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
                            let album = Album(
                                id: songResponse.album.id,
                                spotifyId: songResponse.album.id,
                                rank: nil,
                                images: songResponse.album.images,
                                name: songResponse.album.name,
                                artists: songResponse.artists.map {
                                    Artist(id: "album-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
                                },
                                releaseDate: songResponse.album.releaseDate
                            )
                            let rank = index + 1
                            let artists = songResponse.artists.map {
                                Artist(id: "song-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
                            }
                            return Song(
                                id: "\(key)-\(rank)-\(songResponse.id)",
                                spotifyId: songResponse.id,
                                rank: rank,
                                album: album,
                                artists: artists,
                                durationMs: songResponse.durationMs,
                                name: songResponse.name,
                                popularity: songResponse.popularity
                            )
                        }
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.calculateTopAlbums()
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
                            let rank = index + 1
                            return Artist(
                                id: "\(key)-\(rank)-\(artistResponse.id)",
                                spotifyId: artistResponse.id,
                                rank: rank,
                                images: artistResponse.images,
                                name: artistResponse.name,
                                popularity: artistResponse.popularity,
                                genres: artistResponse.genres
                            )
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

    private func calculateTopAlbums() {
        let keys = ["short", "medium", "long"]
        for key in keys {
            guard let songs = topSongsList[key] else {
                self.topAlbumsList[key] = []
                continue
            }

            // Group songs by album ID
            var albumToSongs: [String: [Song]] = [:]
            for song in songs {
                albumToSongs[song.album.id, default: []].append(song)
            }

            // Filter: "if there's more than one top song with a shared album, include it on top albums"
            let filteredAlbums = albumToSongs.filter { $1.count > 1 }

            // Sort by:
            // 1. Number of songs in top tracks (descending)
            // 2. Rank of the highest song (ascending - lower is better)
            let sortedAlbumIds = filteredAlbums.keys.sorted { id1, id2 in
                let songs1 = filteredAlbums[id1]!
                let songs2 = filteredAlbums[id2]!

                if songs1.count != songs2.count {
                    return songs1.count > songs2.count
                }

                let bestRank1 = songs1.compactMap { $0.rank }.min() ?? Int.max
                let bestRank2 = songs2.compactMap { $0.rank }.min() ?? Int.max

                return bestRank1 < bestRank2
            }

            self.topAlbumsList[key] = sortedAlbumIds.enumerated().map { index, albumId in
                let songs = filteredAlbums[albumId]!
                let firstSong = songs[0] // Representative song to get album details
                return Album(
                    id: "\(key)-\(index + 1)-\(albumId)",
                    spotifyId: albumId,
                    rank: index + 1,
                    images: firstSong.album.images,
                    name: firstSong.album.name,
                    artists: firstSong.artists,
                    releaseDate: firstSong.album.releaseDate
                )
            }
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
        let requestHeaders: [String: String] = [
            "Authorization": "\(authorizationTokenTypeStr) \(authorizationAccessTokenStr)"
        ]
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

    func getArtistsForTimeRange(
        range: String,
        offset: Int,
        userCompletionHandler: @escaping (TopArtistsResponse?) -> Void
    ) {
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
        let requestHeaders: [String: String] = [
            "Authorization": authorizationTokenTypeStr + " " + authorizationAccessTokenStr
        ]
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

    func reset() {
        DispatchQueue.main.async {
            self.topSongsResponse = [:]
            self.topArtistsResponse = [:]
            self.topSongsList = [:]
            self.topArtistsList = [:]
            self.topAlbumsList = [:]
            self.userProfile = nil
            self.accessToken = ""
            self.tokenType = ""
        }
    }
}

// MARK: - Individual Item Fetching
extension UserTopItems {
    func getTrack(id: String, userCompletionHandler: @escaping (SongResponse?) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/tracks/\(id)"

        guard let url = components.url else {
            userCompletionHandler(nil)
            return
        }

        let requestHeaders: [String: String] = ["Authorization": "\(tokenType) \(accessToken)"]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                userCompletionHandler(nil)
                return
            }
            do {
                let track = try JSONDecoder().decode(SongResponse.self, from: data)
                userCompletionHandler(track)
            } catch {
                print("Error decoding track: \(error)")
                userCompletionHandler(nil)
            }
        }.resume()
    }

    func getArtist(id: String, userCompletionHandler: @escaping (ArtistResponse?) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/artists/\(id)"

        guard let url = components.url else {
            userCompletionHandler(nil)
            return
        }

        let requestHeaders: [String: String] = ["Authorization": "\(tokenType) \(accessToken)"]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                userCompletionHandler(nil)
                return
            }
            do {
                let artist = try JSONDecoder().decode(ArtistResponse.self, from: data)
                userCompletionHandler(artist)
            } catch {
                print("Error decoding artist: \(error)")
                userCompletionHandler(nil)
            }
        }.resume()
    }

    func getAlbum(id: String, userCompletionHandler: @escaping (AlbumResponse?) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/albums/\(id)"

        guard let url = components.url else {
            userCompletionHandler(nil)
            return
        }

        let requestHeaders: [String: String] = ["Authorization": "\(tokenType) \(accessToken)"]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                userCompletionHandler(nil)
                return
            }
            do {
                let album = try JSONDecoder().decode(AlbumResponse.self, from: data)
                userCompletionHandler(album)
            } catch {
                print("Error decoding album: \(error)")
                userCompletionHandler(nil)
            }
        }.resume()
    }
}
