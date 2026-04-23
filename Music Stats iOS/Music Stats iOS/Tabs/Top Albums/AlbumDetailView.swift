// AlbumDetailView.swift

import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?
    let songCount: Int?

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

                    Text(album.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: album.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Release Date", value: album.releaseDate)
                        if let totalTracks = album.totalTracks {
                            DetailRow(label: "Total Tracks", value: "\(totalTracks)")
                        }
                        if let label = album.label {
                            DetailRow(label: "Label", value: label)
                        }
                        if let popularity = album.popularity {
                            DetailRow(label: "Popularity", value: "\(popularity)/100")
                        }
                        if let songCount = songCount {
                            DetailRow(label: "Songs in Your Top 50", value: "\(songCount)")
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
        .task {
            do {
                album = try await userTopItems.getAlbum(id: spotifyId)
            } catch {
                // album remains nil; view shows "Failed to load album details."
            }
            isLoading = false
        }
    }
}
