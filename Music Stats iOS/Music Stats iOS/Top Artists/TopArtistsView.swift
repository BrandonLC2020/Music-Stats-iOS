//
//  TopArtists.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct TopArtistsView: View {
    var userTopItems: UserTopItems
    @State var selection: Int = 0
    var accessToken: String
    var tokenType: String
    
    
    
    init(access: String, type: String) {
        self.accessToken = access
        self.tokenType = type
        self.userTopItems = UserTopItems(access: accessToken, token: type)
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    VStack {
                        //Text("Top Artists").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        ScrollView {
                            Picker(selection: $selection, label: Text("Time Period")) {
                                Text("Short Term").tag(0)
                                Text("Medium Term").tag(1)
                                Text("Long Term").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding([.top, .leading, .trailing])
                            
                            if selection == 0 {
                                VStack(/*spacing: -geometry.size.height/1.175*/) {
                                    ForEach(userTopItems.topArtistsList["short"]!, id: \.self) { artist in
                                        ArtistCard(artist: artist, parentGeo: geometry)
                                            //.frame(width: geometry.size.width/1.07, height: geometry.size.height/7.5)
                                    }
                                }
                            } else if selection == 1 {
                                VStack(/*spacing: -geometry.size.height/1.175*/) {
                                    ForEach(userTopItems.topArtistsList["medium"]!, id: \.self) { artist in
                                        ArtistCard(artist: artist, parentGeo: geometry)//.frame(width: geometry.size.width, height: geometry.size.height)
                                    }
                                }
                            } else {
                                VStack(/*spacing: -geometry.size.height/1.175*/) {
                                    ForEach(userTopItems.topArtistsList["long"]!, id: \.self) { artist in
                                        ArtistCard(artist: artist, parentGeo: geometry)
//                                            .aspectRatio(1, contentMode: .fit)
//                                            .frame(minWidth: geometry.size.width/1.07, idealWidth: geometry.size.width/1.07, maxWidth: geometry.size.width/1.07, minHeight: geometry.size.height/7.5, idealHeight: geometry.size.height/7.5, maxHeight: geometry.size.height/7.5)
//                                            .clipped()
                                            //.frame(width: geometry.size.width/1.07, height: geometry.size.height/7.5)
                                            //.frame(width: geometry.size.width, height: geometry.size.height)
                                        
                                    }
                                }
                            }
                        }//.padding(.bottom)
                    }
                }
            }.navigationTitle("Top Songs")
        }//.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
    }
}
