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
    var twoColumnGrid = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
    
    
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
                        Picker(selection: $selection, label: Text("Time Period")) {
                            Text("Past Month").tag(0)
                            Text("Past 6 Months").tag(1)
                            Text("Past Years").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding([.top, .leading, .trailing])
                        //Text("Top Artists").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        ScrollView {
                            
                            
                            if selection == 0 {
                                VStack {
                                    ForEach(userTopItems.topArtistsList["short"]!, id: \.self) { artist in
                                        if (artist.rank != 50) {
                                            ArtistCard(artist: artist, parentGeo: geometry)
                                        } else {
                                            ArtistCard(artist: artist, parentGeo: geometry).padding(.bottom)
                                        }
                                    }
                                }
                            } else if selection == 1 {
                                VStack(/*spacing: -geometry.size.height/1.175*/) {
                                    ForEach(userTopItems.topArtistsList["medium"]!, id: \.self) { artist in
                                        if (artist.rank != 50) {
                                            ArtistCard(artist: artist, parentGeo: geometry)
                                        } else {
                                            ArtistCard(artist: artist, parentGeo: geometry).padding(.bottom)
                                        }
                                    }
                                }
                            } else {
                                VStack(/*spacing: -geometry.size.height/1.175*/) {
                                    ForEach(userTopItems.topArtistsList["long"]!, id: \.self) { artist in
                                        if (artist.rank != 50) {
                                            ArtistCard(artist: artist, parentGeo: geometry)
                                        } else {
                                            ArtistCard(artist: artist, parentGeo: geometry).padding(.bottom)
                                        }
                                    }
                                }
                            }
                        }//.padding(.bottom)
                    }
                }
                .navigationTitle("Top Artists")
                .navigationBarTitleDisplayMode(.large)
            }
        }//.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
    }
}
