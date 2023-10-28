//
//  TopSongs.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct TopSongsView: View {
    var topSongs: [String:[Song]]
    @State var selection:Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    VStack {
                        //Text("Top Songs").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        ScrollView {
                            Picker(selection: $selection, label: Text("Time Period")) {
                                                        Text("Short Term").tag(0)
                                                        Text("Medium Term").tag(1)
                                                        Text("Long Term").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.all, 10)
                            if selection == 0 {
                                LazyVStack(spacing: -geometry.size.height/1.175) {
                                    ForEach(topSongs["short"]!, id: \.self) { song in
                                        SongCard(song: song).frame(width: geometry.size.width, height: geometry.size.height)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
}

#Preview {
    TopSongsView(topSongs: ["short":[Song(rank: 1, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14"), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88), Song(rank: 2, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273881d8d8378cd01099babcd44", height: 640, width: 640)], name: "UTOPIA", release_date: "2023-07-28"), artists: [Artist(name: "Travis Scott", artistId: "0Y5tJX1MQlPlqiwlOH1tJY")], duration_ms: 353754, name: "TELEKINESIS (feat. SZA & Future)", popularity: 90), Song(rank: 3, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b27302afda5a83c34b02c4404a3b", height: 640, width: 640)], name: "Summertime Friends", release_date: "2023-09-08"), artists: [Artist(name: "The Chainsmokers", artistId: "69GGBxA162lTqCwzJG5jLp")], duration_ms: 136586, name: "Summertime Friends", popularity: 75), Song(rank: 4, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273c6b31d9de8df430efab41836", height: 640, width: 640)], name: "The Melodic Blue (Deluxe)", release_date: "2022-10-28"), artists: [Artist(name: "Baby Keem", artistId: "5SXuuuRpukkTvsLuUknva1")], duration_ms: 156040, name: "16", popularity: 54), Song(rank: 5, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b27313e54d6687e65678d60466c2", height: 640, width: 640)], name: "HEROES & VILLAINS", release_date: "2022-12-02"), artists: [Artist(name: "Metro Boomin", artistId: "0iEtIxbK0KxaSlF7G42ZOp")], duration_ms: 194786, name: "Trance (with Travis Scott & Young Thug)", popularity: 88)]])
}
