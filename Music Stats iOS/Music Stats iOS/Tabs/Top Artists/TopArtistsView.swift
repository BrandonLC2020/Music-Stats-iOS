// TopArtistsView.swift

import SwiftUI

struct TopArtistsView: View {
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

                if let artists = artistsForSelection() {
                    ScrollView {
                        // Add spacing and padding for a clean layout.
                        VStack(spacing: 10) {
                            ForEach(artists, id: \.self) { artist in
                                // The call to ArtistCard is now much simpler.
                                ArtistCard(artist: artist)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                } else {
                    Spacer()
                    ProgressView("Loading Artists...")
                    Spacer()
                }
            }
            .navigationTitle("Top Artists")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func artistsForSelection() -> [Artist]? {
        switch selection {
        case 0:
            return userTopItems.topArtistsList["short"]
        case 1:
            return userTopItems.topArtistsList["medium"]
        case 2:
            return userTopItems.topArtistsList["long"]
        default:
            return nil
        }
    }
}
