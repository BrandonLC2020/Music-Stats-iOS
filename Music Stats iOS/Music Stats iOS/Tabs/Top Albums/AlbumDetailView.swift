// AlbumDetailView.swift

import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?
    
    @State private var album: AlbumResponse?
    @State private var isLoading = true

    private func artistsToString(artists: [ArtistResponse]?) -> String {
        return artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown Artist"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Album Details...")
                    .padding(.top, 50)
            } else if let album = album {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Large Album Cover
                    AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.bottom, 10)

                    // 2. Album Title
                    Text(album.name)
                        .font(.largeTitle)
                        .bold()

                    // 3. Artist(s)
                    Text(artistsToString(artists: album.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Divider()

                    // 4. Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Release Date", value: album.release_date)
                        if let totalTracks = album.total_tracks {
                            DetailRow(label: "Total Tracks", value: "\(totalTracks)")
                        }
                        if let label = album.label {
                            DetailRow(label: "Label", value: label)
                        }
                        if let popularity = album.popularity {
                            DetailRow(label: "Popularity", value: "\(popularity)/100")
                        }
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load album details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchAlbumDetails()
        }
    }
    
    private func fetchAlbumDetails() {
        userTopItems.getAlbum(id: spotifyId) { response in
            DispatchQueue.main.async {
                self.album = response
                self.isLoading = false
            }
        }
    }
}
