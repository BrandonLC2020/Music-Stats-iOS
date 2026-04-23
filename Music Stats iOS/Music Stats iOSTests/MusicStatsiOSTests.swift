//
//  MusicStatsiOSTests.swift
//  Music Stats iOSTests
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import Testing
import Foundation
@testable import Music_Stats_iOS

// MARK: - JSON Decoding Tests

@Suite("JSON Decoding")
struct JSONDecodingTests {

    @Test("SongResponse decodes snake_case fields correctly")
    func songResponseDecoding() throws {
        let json = """
        {
            "id": "song123",
            "name": "Test Song",
            "popularity": 85,
            "duration_ms": 210000,
            "artists": [
                { "id": "artist1", "name": "Test Artist", "popularity": 90, "genres": ["pop"] }
            ],
            "album": {
                "id": "album1",
                "name": "Test Album",
                "release_date": "2023-01-01",
                "images": [{ "url": "https://example.com/img.jpg", "height": 300, "width": 300 }]
            }
        }
        """.data(using: .utf8)!

        let song = try JSONDecoder().decode(SongResponse.self, from: json)

        #expect(song.id == "song123")
        #expect(song.name == "Test Song")
        #expect(song.popularity == 85)
        #expect(song.durationMs == 210000)
        #expect(song.artists.count == 1)
        #expect(song.artists[0].name == "Test Artist")
        #expect(song.album.name == "Test Album")
        #expect(song.album.releaseDate == "2023-01-01")
    }

    @Test("AlbumResponse decodes snake_case fields correctly")
    func albumResponseDecoding() throws {
        let json = """
        {
            "id": "album123",
            "name": "Test Album",
            "release_date": "2022-06-15",
            "images": [{ "url": "https://img.com/a.jpg", "height": 640, "width": 640 }],
            "total_tracks": 12,
            "label": "Test Label",
            "popularity": 75
        }
        """.data(using: .utf8)!

        let album = try JSONDecoder().decode(AlbumResponse.self, from: json)

        #expect(album.id == "album123")
        #expect(album.name == "Test Album")
        #expect(album.releaseDate == "2022-06-15")
        #expect(album.images.count == 1)
        #expect(album.images[0].url == "https://img.com/a.jpg")
        #expect(album.totalTracks == 12)
        #expect(album.label == "Test Label")
        #expect(album.popularity == 75)
    }

    @Test("ArtistResponse decodes correctly with optional fields")
    func artistResponseDecoding() throws {
        let json = """
        {
            "id": "artist123",
            "name": "Test Artist",
            "popularity": 88,
            "genres": ["rock", "indie"],
            "images": [{ "url": "https://img.com/artist.jpg", "height": 320, "width": 320 }]
        }
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(ArtistResponse.self, from: json)

        #expect(artist.id == "artist123")
        #expect(artist.name == "Test Artist")
        #expect(artist.popularity == 88)
        #expect(artist.genres == ["rock", "indie"])
        #expect(artist.images?.count == 1)
        #expect(artist.images?[0].url == "https://img.com/artist.jpg")
    }

    @Test("ArtistResponse handles missing optional fields")
    func artistResponseMissingOptionals() throws {
        let json = """
        {
            "id": "artist456",
            "name": "Minimal Artist"
        }
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(ArtistResponse.self, from: json)

        #expect(artist.id == "artist456")
        #expect(artist.name == "Minimal Artist")
        #expect(artist.popularity == nil)
        #expect(artist.genres == nil)
        #expect(artist.images == nil)
    }

    @Test("UserProfileResponse decodes snake_case fields correctly")
    func userProfileResponseDecoding() throws {
        let json = """
        {
            "id": "user123",
            "display_name": "Test User",
            "email": "test@example.com",
            "images": [{ "url": "https://img.com/user.jpg", "height": 200, "width": 200 }]
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(UserProfileResponse.self, from: json)

        #expect(profile.id == "user123")
        #expect(profile.displayName == "Test User")
        #expect(profile.email == "test@example.com")
        #expect(profile.images?.count == 1)
    }

    @Test("AccessTokenResponse decodes snake_case fields correctly")
    func accessTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "myAccessToken",
            "token_type": "Bearer",
            "scope": "user-top-read",
            "expires_in": 3600,
            "refresh_token": "myRefreshToken"
        }
        """.data(using: .utf8)!

        let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: json)

        #expect(tokenResponse.accessToken == "myAccessToken")
        #expect(tokenResponse.tokenType == "Bearer")
        #expect(tokenResponse.scope == "user-top-read")
        #expect(tokenResponse.expiresIn == 3600)
        #expect(tokenResponse.refreshToken == "myRefreshToken")
    }

    @Test("AccessTokenResponse handles nil refreshToken")
    func accessTokenResponseNilRefreshToken() throws {
        let json = """
        {
            "access_token": "myAccessToken",
            "token_type": "Bearer",
            "scope": "user-top-read",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: json)

        #expect(tokenResponse.refreshToken == nil)
    }

    @Test("TopSongsResponse decodes items array correctly")
    func topSongsResponseDecoding() throws {
        let json = """
        {
            "href": "https://api.spotify.com/v1/me/top/tracks",
            "limit": 50,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": 1,
            "items": [
                {
                    "id": "song1",
                    "name": "Track One",
                    "popularity": 70,
                    "duration_ms": 180000,
                    "artists": [{ "id": "a1", "name": "Artist One" }],
                    "album": {
                        "id": "alb1",
                        "name": "Album One",
                        "release_date": "2021-01-01",
                        "images": []
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TopSongsResponse.self, from: json)

        #expect(response.total == 1)
        #expect(response.limit == 50)
        #expect(response.offset == 0)
        #expect(response.next == nil)
        #expect(response.items.count == 1)
        #expect(response.items[0].name == "Track One")
        #expect(response.items[0].durationMs == 180000)
    }

    @Test("TopArtistsResponse decodes items array correctly")
    func topArtistsResponseDecoding() throws {
        let json = """
        {
            "href": "https://api.spotify.com/v1/me/top/artists",
            "limit": 50,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": 2,
            "items": [
                { "id": "a1", "name": "Artist One", "popularity": 95, "genres": ["pop"] },
                { "id": "a2", "name": "Artist Two", "popularity": 80, "genres": [] }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TopArtistsResponse.self, from: json)

        #expect(response.total == 2)
        #expect(response.items.count == 2)
        #expect(response.items[0].name == "Artist One")
        #expect(response.items[1].popularity == 80)
    }

    @Test("ImageResponse decodes all fields including optional dimensions")
    func imageResponseDecoding() throws {
        let jsonWithDimensions = """
        { "url": "https://img.com/full.jpg", "height": 640, "width": 640 }
        """.data(using: .utf8)!

        let jsonNoDimensions = """
        { "url": "https://img.com/nodims.jpg" }
        """.data(using: .utf8)!

        let withDims = try JSONDecoder().decode(ImageResponse.self, from: jsonWithDimensions)
        let noDims = try JSONDecoder().decode(ImageResponse.self, from: jsonNoDimensions)

        #expect(withDims.url == "https://img.com/full.jpg")
        #expect(withDims.height == 640)
        #expect(withDims.width == 640)

        #expect(noDims.url == "https://img.com/nodims.jpg")
        #expect(noDims.height == nil)
        #expect(noDims.width == nil)
    }
}

// MARK: - UserTopItems Tests

@MainActor
@Suite("UserTopItems")
struct UserTopItemsTests {

    @Test("Initial state has empty collections and blank tokens")
    func initialState() {
        let sut = UserTopItems()

        #expect(sut.topSongsResponse.isEmpty)
        #expect(sut.topArtistsResponse.isEmpty)
        #expect(sut.topSongsList.isEmpty)
        #expect(sut.topArtistsList.isEmpty)
        #expect(sut.topAlbumsList.isEmpty)
        #expect(sut.userProfile == nil)
        #expect(sut.accessToken == "")
        #expect(sut.tokenType == "")
    }

    @Test("reset() clears tokens and all collections")
    func resetClearsAllData() async throws {
        let sut = UserTopItems()
        let image = ImageResponse(url: "https://example.com", height: 100, width: 100)
        let album = Album(
            id: "alb1", spotifyId: "alb1", rank: 1,
            images: [image], name: "Album", artists: nil, releaseDate: "2023-01-01"
        )
        let song = Song(
            id: "short-1-song1", spotifyId: "song1", rank: 1,
            album: album, artists: [], durationMs: 180000, name: "Song", popularity: 80
        )

        sut.topSongsList["short"] = [song]
        sut.accessToken = "some-token"
        sut.tokenType = "Bearer"
        sut.userProfile = UserProfile(id: "user1", displayName: "Test User", email: nil, images: nil)

        sut.reset()

        #expect(sut.topSongsResponse.isEmpty)
        #expect(sut.topArtistsResponse.isEmpty)
        #expect(sut.topSongsList.isEmpty)
        #expect(sut.topArtistsList.isEmpty)
        #expect(sut.topAlbumsList.isEmpty)
        #expect(sut.userProfile == nil)
        #expect(sut.accessToken == "")
        #expect(sut.tokenType == "")
    }

    @Test("fetchState starts as .loading")
    func fetchStateInitiallyLoading() {
        let sut = UserTopItems()
        #expect(sut.fetchState == .loading)
    }

    @Test("reset() sets fetchState back to .loading")
    func resetClearsFetchState() {
        let sut = UserTopItems()
        sut.fetchState = .error
        sut.reset()
        #expect(sut.fetchState == .loading)
    }

    @Test("retry() immediately sets fetchState to .loading")
    func retrySetsFetchStateToLoading() {
        let sut = UserTopItems()
        sut.fetchState = .error
        sut.retry()
        #expect(sut.fetchState == .loading)
    }
}

// MARK: - Top Albums Calculation Tests

@MainActor
@Suite("Top Albums Calculation")
struct TopAlbumsCalculationTests {

    private func makeSong(
        name: String,
        spotifyId: String,
        albumId: String,
        albumName: String,
        rank: Int,
        timeRange: String = "short"
    ) -> Song {
        let image = ImageResponse(url: "https://img.com", height: 300, width: 300)
        let album = Album(
            id: albumId, spotifyId: albumId, rank: nil,
            images: [image], name: albumName, artists: nil, releaseDate: "2023-01-01"
        )
        return Song(
            id: "\(timeRange)-\(rank)-\(spotifyId)", spotifyId: spotifyId, rank: rank,
            album: album, artists: [], durationMs: 200000, name: name, popularity: 80
        )
    }

    @Test("Albums with only one top song are excluded")
    func singleSongAlbumsExcluded() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song A", spotifyId: "s1", albumId: "alb1", albumName: "Album 1", rank: 1),
            makeSong(name: "Song B", spotifyId: "s2", albumId: "alb2", albumName: "Album 2", rank: 2),
            makeSong(name: "Song C", spotifyId: "s3", albumId: "alb3", albumName: "Album 3", rank: 3)
        ]
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.isEmpty == true)
    }

    @Test("Albums with two or more top songs are included")
    func multiSongAlbumsIncluded() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song A", spotifyId: "s1", albumId: "alb1", albumName: "Hit Album", rank: 1),
            makeSong(name: "Song B", spotifyId: "s2", albumId: "alb1", albumName: "Hit Album", rank: 2),
            makeSong(name: "Song C", spotifyId: "s3", albumId: "alb2", albumName: "Other Album", rank: 3)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 1)
        #expect(albums?[0].name == "Hit Album")
    }

    @Test("Albums sorted by song count descending, then by best rank ascending")
    func albumsSortedBySongCountThenBestRank() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Album Two", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Album Two", rank: 4),
            makeSong(name: "Song 5", spotifyId: "s5", albumId: "alb2", albumName: "Album Two", rank: 5)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 2)
        #expect(albums?[0].name == "Album Two")
        #expect(albums?[1].name == "Album One")
    }

    @Test("Albums with equal song count sorted by best song rank (lower is better)")
    func albumsWithTiedCountSortedByBestRank() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Better Album", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Better Album", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Worse Album", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Worse Album", rank: 4)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 2)
        #expect(albums?[0].name == "Better Album")
        #expect(albums?[1].name == "Worse Album")
    }

    @Test("Albums are assigned sequential ranks starting from 1")
    func albumsAssignedSequentialRanks() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Album Two", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Album Two", rank: 4)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?[0].rank == 1)
        #expect(albums?[1].rank == 2)
    }

    @Test("calculateTopAlbums produces empty arrays for all three time ranges when no songs")
    func emptyInputProducesEmptyOutputForAllRanges() {
        let sut = UserTopItems()
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.isEmpty == true)
        #expect(sut.topAlbumsList["medium"]?.isEmpty == true)
        #expect(sut.topAlbumsList["long"]?.isEmpty == true)
    }

    @Test("Album IDs encode time range and rank for SwiftUI uniqueness")
    func albumIdEncoding() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2)
        ]
        sut.calculateTopAlbums()
        let album = sut.topAlbumsList["short"]?.first
        #expect(album?.id == "short-1-alb1")
    }

    @Test("calculateTopAlbums is independent per time range")
    func independentPerTimeRange() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Hit Album", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Hit Album", rank: 2)
        ]
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.count == 1)
        #expect(sut.topAlbumsList["medium"]?.isEmpty == true)
        #expect(sut.topAlbumsList["long"]?.isEmpty == true)
    }
}

// MARK: - AuthManager Tests

@MainActor
@Suite("AuthManager")
struct AuthManagerTests {

    @Test("logout() clears tokens and sets isAuthenticated to false")
    func logoutClearsState() {
        let sut = AuthManager()
        sut.accessToken = "some-access-token"
        sut.tokenType = "Bearer"

        sut.logout()

        #expect(sut.accessToken == nil)
        #expect(sut.tokenType == nil)
        #expect(sut.isAuthenticated == false)
    }
}
