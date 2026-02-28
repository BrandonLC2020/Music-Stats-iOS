// SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    var song: Song

    private func artistsToString() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }

    private func formatDuration(ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Large Album Cover
                AsyncImage(url: URL(string: song.album.images.first?.url ?? "")) { image in
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

                // 2. Song Title
                Text(song.name)
                    .font(.largeTitle)
                    .bold()

                // 3. Artist(s)
                Text(artistsToString())
                    .font(.title2)
                    .foregroundColor(.secondary)

                Divider()

                // 4. Details Section
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Album", value: song.album.name)
                    DetailRow(label: "Release Date", value: song.album.release_date)
                    DetailRow(label: "Duration", value: formatDuration(ms: song.duration_ms))
                    DetailRow(label: "Popularity", value: "\(song.popularity)/100")
                    if let rank = song.rank {
                        DetailRow(label: "Rank", value: "#\(rank)")
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

