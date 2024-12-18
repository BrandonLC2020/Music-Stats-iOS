//
//  SongCard.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct SongCard: View {
    var song: Song
    var parentGeo: GeometryProxy
    
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
        GeometryReader { geometry in
            ZStack {
                HStack(alignment: .center) {
                    AsyncImage(url: URL(string: song.album.images[0].url)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .cornerRadius(15.0)
                    .blur(radius: 4.2)
                    .scaledToFill()
                    //.scaledToFit()
                    .frame(width: parentGeo.size.width/1.07, height: parentGeo.size.height/7.5)
                    //.frame(width: geometry.size.width,  height: geometry.size.height)
                    //.frame(width: geometry.size.width/1.07, height: geometry.size.height/7.5)
                    .clipped()
                }.cornerRadius(15.0)
                RoundedRectangle(cornerRadius: 15.0).frame(alignment: .center)
                    .foregroundColor(.gray.opacity(0.7))
                    .frame(width: parentGeo.size.width/1.07, height: parentGeo.size.height/7.5)
                    //.frame(width: geometry.size.width,  height: geometry.size.height)
                    //.frame(width: geometry.size.width/1.07, height: geometry.size.height/7.5)
                HStack(alignment: .center) {
                    //rank
                    Text(String(song.rank ?? Int()))
                        .bold()
                        .frame(width:geometry.size.width/16, height:geometry.size.width/40)
                        .padding(.leading)
                    //album cover
                    AsyncImage(url: URL(string: song.album.images[0].url)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: geometry.size.width/5.0, height: geometry.size.width/5.0)
                    .cornerRadius(15.0)
                    .padding(.all)
                    //song title
                    VStack(alignment: .leading) {
                        Text(song.name)
                            .bold()
                            .lineLimit(1)
                        Text(artistsToStr())
                            .lineLimit(1)
                    }
                    .padding(.trailing)
                    
                    Spacer()
                }//.padding(.all)
            }
            //.frame(alignment: .top)
            
        }
        //.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .frame(width: parentGeo.size.width/1.07, height: parentGeo.size.height/7.5)
    }
}

//#Preview {
//    SongCard(song: Song(rank: 1, album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14"), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88))
//}
