//
//  TopSongs.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct TopSongsView: View {
    var topSongs: [Song]
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack {
                        ForEach(topSongs, id: \.self) { song in
                            SongCard(song: song)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TopSongsView(topSongs: [Song(rank: 1, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14"), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88), Song(rank: 2, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273881d8d8378cd01099babcd44", height: 640, width: 640)], name: "UTOPIA", release_date: "2023-07-28"), artists: [Artist(name: "Travis Scott", artistId: "0Y5tJX1MQlPlqiwlOH1tJY")], duration_ms: 353754, name: "TELEKINESIS (feat. SZA & Future)", popularity: 90)])
}
