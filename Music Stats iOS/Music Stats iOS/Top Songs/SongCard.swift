//
//  SongCard.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct SongCard: View {
    var song: SongResponse
    
    func artistsToStr() -> String {
        var result : String = ""
        for artist in song.artists {
            result += artist.name + ", "
        }
        let endIndex = result.index(result.endIndex, offsetBy: -2)
        let truncated = result[..<endIndex]
        return String(truncated)
    }
    
    var body: some View {
        ZStack {
            HStack {
                //album cover
                
                //song title
                VStack{
                    Text(song.name)
                    Text(artistsToStr())
                }
                
            }
        }
    }
}

#Preview {
    SongCard(song: SongResponse(album: AlbumResponse(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14"), artists: [ArtistResponse(name: "Post Malone", id: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88))
}
