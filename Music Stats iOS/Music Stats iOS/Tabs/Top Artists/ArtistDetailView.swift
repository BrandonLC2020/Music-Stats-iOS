// ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?
    
    @State private var artist: ArtistResponse?
    @State private var isLoading = true

    private func genresToString(genres: [String]?) -> String {
        return genres?.joined(separator: ", ") ?? "N/A"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Artist Details...")
                    .padding(.top, 50)
            } else if let artist = artist {
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
                        if let genres = artist.genres, !genres.isEmpty {
                            DetailRow(label: "Genres", value: genresToString(genres: genres))
                        }
                        if let popularity = artist.popularity {
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
                Text("Failed to load artist details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchArtistDetails()
        }
    }
    
    private func fetchArtistDetails() {
        userTopItems.getArtist(id: spotifyId) { response in
            DispatchQueue.main.async {
                self.artist = response
                self.isLoading = false
            }
        }
    }
}

struct ArtistDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistDetailView(spotifyId: "testId", rank: 1)
            .environmentObject(UserTopItems())
    }
}
