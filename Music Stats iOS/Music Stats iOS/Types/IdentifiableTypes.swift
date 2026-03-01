//
//  IdentifiableTypes.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/26/23.
//

import Foundation

struct TopSongs: Identifiable, Hashable {
    let id = UUID()
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [Song]
}

struct TopArtists: Identifiable, Hashable {
    let id = UUID()
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [Artist]
}
    

struct Song: Identifiable, Hashable {
    var id: String // Unique ID for SwiftUI (e.g., "short-1-spotifyId")
    var spotifyId: String
    var rank: Int?
    var album: Album
    var artists: [Artist]
    var duration_ms: Int //in milliseconds
    var name: String
    var popularity: Int
}

struct Artist: Identifiable, Hashable {
    var id: String // Unique ID for SwiftUI (e.g., "short-1-spotifyId")
    var spotifyId: String
    var rank: Int?
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var genres: [String]?
}

struct Album: Identifiable, Hashable {
    var id: String
    var images: [ImageResponse]
    var name: String
    var release_date: String
}

//struct Image: Identifiable {
//    let id = UUID()
//    var url: String
//    var height: Int?
//    var width: Int?
//}
