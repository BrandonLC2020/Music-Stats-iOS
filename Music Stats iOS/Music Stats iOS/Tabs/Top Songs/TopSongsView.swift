//
//  TopSongs.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

import SwiftUI

struct TopSongsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    Picker(selection: $selection, label: Text("Time Period")) {
                        Text("Past Month").tag(0)
                        Text("Past 6 Months").tag(1)
                        Text("Past Years").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.top, .leading, .trailing])
                    
                    if let songs = songsForSelection() {
                        ScrollView {
                            VStack {
                                ForEach(songs, id: \.self) { song in
                                    if (song.rank != 50) {
                                        SongCard(song: song, parentGeo: geometry)
                                    } else {
                                        SongCard(song: song, parentGeo: geometry).padding(.bottom)
                                    }
                                }
                            }
                        }
                    } else {
                        Spacer()
                        ProgressView("Loading Songs...")
                        Spacer()
                    }
                }
                .navigationTitle("Top Songs")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }

    private func songsForSelection() -> [Song]? {
        switch selection {
        case 0:
            return userTopItems.topSongsList["short"]
        case 1:
            return userTopItems.topSongsList["medium"]
        case 2:
            return userTopItems.topSongsList["long"]
        default:
            return nil
        }
    }
}
