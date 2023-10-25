//
//  ResponseTypes.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

struct TopSongsResponse: Codable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SongResponse]
}

struct TopArtistsResponse: Codable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [ArtistResponse]
}
    

struct SongResponse: Codable {
    var album: AlbumResponse
    var artists: [ArtistResponse]
    var duration_ms: Int //in milliseconds
    var name: String
    var popularity: Int
    
}

struct ArtistResponse: Codable {
    
}

struct AlbumResponse: Codable {
    
}
