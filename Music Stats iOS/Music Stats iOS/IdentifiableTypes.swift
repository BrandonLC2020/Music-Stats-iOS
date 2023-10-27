//
//  IdentifiableTypes.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/26/23.
//

import Foundation

struct TopSongs: Identifiable {
    let id = UUID()
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [Song]
}

struct TopArtists: Identifiable {
    let id = UUID()
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [Artist]
}
    

struct Song: Identifiable {
    let id = UUID()
    var rank: Int?
    var album: Album
    var artists: [Artist]
    var duration_ms: Int //in milliseconds
    var name: String
    var popularity: Int
}

struct Artist: Identifiable {
    let id = UUID()
    var rank: Int?
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var artistId: String
}

struct Album: Identifiable {
    let id = UUID()
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
