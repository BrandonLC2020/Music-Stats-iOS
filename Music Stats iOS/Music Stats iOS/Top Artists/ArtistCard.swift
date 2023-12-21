//
//  ArtistCard.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 12/21/23.
//

import Foundation
import SwiftUI

struct ArtistCard: View {
    var artist: Artist
    var parentGeo: GeometryProxy
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(alignment: .center) {
                    AsyncImage(url: URL(string: artist.images![0].url)) { image in
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
                    Text(String(artist.rank ?? Int()))
                        .bold()
                        .frame(width:geometry.size.width/16, height:geometry.size.width/40)
                        .padding(.leading)
                    //album cover
                    AsyncImage(url: URL(string: artist.images![0].url)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: geometry.size.width/5.0, height: geometry.size.width/5.0)
                    .cornerRadius(15.0)
                    .padding(.all)
                    //song title
                    VStack(alignment: .leading) {
                        Text(artist.name)
                            .bold()
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
