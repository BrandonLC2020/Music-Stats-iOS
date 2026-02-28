// TopSongsView.swift

import SwiftUI

struct TopSongsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0

    var body: some View {
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
                    List(songs) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            SongCard(song: song)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .padding(.bottom)
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
