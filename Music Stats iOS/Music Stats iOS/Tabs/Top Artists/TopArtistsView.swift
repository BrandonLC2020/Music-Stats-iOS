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
                    List(artists) { artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            ArtistCard(artist: artist)
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
