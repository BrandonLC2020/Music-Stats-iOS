// TopArtistsView.swift

import SwiftUI

struct TopArtistsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0

    var body: some View {
        NavigationView {
            if let artists = artistsForSelection() {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(artists) { artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                ArtistCard(artist: artist)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .navigationTitle("Top Artists")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Picker("Time Period", selection: $selection) {
                                Text("Past Month").tag(0)
                                Text("Past 6 Months").tag(1)
                                Text("Past Years").tag(2)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectionTitle)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                VStack {
                    ProgressView("Loading Artists...")
                }
                .navigationTitle("Top Artists")
            }
        }
    }

    private var selectionTitle: String {
        switch selection {
        case 0: return "Past Month"
        case 1: return "Past 6 Months"
        case 2: return "Past Years"
        default: return ""
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
