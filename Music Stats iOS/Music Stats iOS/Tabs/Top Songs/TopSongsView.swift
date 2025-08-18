// TopSongsView.swift

import SwiftUI

struct TopSongsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0

    var body: some View {
        // GeometryReader has been removed.
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
                        // Add spacing to the VStack to separate cards.
                        VStack(spacing: 10) {
                            ForEach(songs, id: \.self) { song in
                                // The card is now called without passing any geometry information.
                                SongCard(song: song)
                            }
                        }
                        // Use horizontal padding on the VStack to create margins.
                        .padding(.horizontal)
                        .padding(.bottom)
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
