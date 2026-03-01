// TopAlbumsView.swift

import SwiftUI

struct TopAlbumsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedAlbum: Album?

    var body: some View {
        NavigationStack {
            if let albums = albumsForSelection() {
                if albums.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Top Albums Found")
                            .font(.title2)
                            .bold()
                        Text("We rank albums based on how many of your top 50 songs are from the same album. Listen to more songs from the same album to see them here!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .navigationTitle("Top Albums")
                    .toolbar {
                        timeframeToolbar
                        ProfileToolbarItem()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(albums) { album in
                                Button {
                                    selectedAlbum = album
                                } label: {
                                    AlbumCard(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .id(album.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .id(selection)
                    .navigationDestination(item: $selectedAlbum) { album in
                        AlbumDetailView(spotifyId: album.spotifyId ?? "", rank: album.rank)
                    }
                    .navigationTitle("Top Albums")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        timeframeToolbar
                        ProfileToolbarItem()
                    }
                }
            } else {
                VStack {
                    ProgressView("Calculating Top Albums...")
                }
                .navigationTitle("Top Albums")
                .toolbar {
                    timeframeToolbar
                    ProfileToolbarItem()
                }
            }
        }
    }

    private var timeframeToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Picker("Time Period", selection: $selection) {
                    Text("Past Month").tag(0)
                    Text("Past 6 Months").tag(1)
                    Text("Past Years").tag(2)
                }
            } label: {
                Image(systemName: "calendar")
            }
        }
    }

    private func albumsForSelection() -> [Album]? {
        switch selection {
        case 0:
            return userTopItems.topAlbumsList["short"]
        case 1:
            return userTopItems.topAlbumsList["medium"]
        case 2:
            return userTopItems.topAlbumsList["long"]
        default:
            return nil
        }
    }
}

struct TopAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        TopAlbumsView(userTopItems: UserTopItems())
    }
}

