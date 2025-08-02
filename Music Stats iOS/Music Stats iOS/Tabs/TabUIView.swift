//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI
import Foundation

struct TabUIView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var userTopItems = UserTopItems()

    var body: some View {
        TabView {
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                TopSongsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Top Songs")
                    }
                TopArtistsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.mic")
                        Text("Top Artists")
                    }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                userTopItems.accessToken = accessToken
                userTopItems.tokenType = tokenType
                userTopItems.getTopSongs {}
                userTopItems.getTopArtists {}
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
