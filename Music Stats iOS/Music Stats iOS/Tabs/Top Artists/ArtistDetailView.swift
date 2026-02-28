// ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    var artist: Artist

    private func genresToString() -> String {
        return artist.genres?.joined(separator: ", ") ?? "N/A"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Large Artist Image
                AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
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

                // 2. Artist Name
                Text(artist.name)
                    .font(.largeTitle)
                    .bold()

                Divider()

                // 3. Details Section
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Genres", value: genresToString())
                    if let popularity = artist.popularity {
                        DetailRow(label: "Popularity", value: "\(popularity)/100")
                    }
                    if let rank = artist.rank {
                        DetailRow(label: "Rank", value: "#\(rank)")
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

