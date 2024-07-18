//
//  ResponseTypes.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

struct TopSongsResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SongResponse]
}

struct TopArtistsResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [ArtistResponse]
}
    

struct SongResponse: Codable, Hashable {
    var album: AlbumResponse
    var artists: [ArtistResponse]
    var duration_ms: Int //in milliseconds
    var name: String
    var popularity: Int
}

struct ArtistResponse: Codable, Hashable {
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var id: String
}

struct AlbumResponse: Codable, Hashable {
    var images: [ImageResponse]
    var name: String
    var release_date: String
}

struct ImageResponse: Codable, Hashable {
    var url: String
    var height: Int?
    var width: Int?
}
