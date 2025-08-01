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

    var body: some View {
        TabView {
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                TopSongsView(access: accessToken, type: tokenType)
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Top Songs")
                    }
                    .navigationTitle("Top Songs")
                TopArtistsView(access: accessToken, type: tokenType)
                    .tabItem {
                        Image(systemName: "music.mic")
                        Text("Top Artists")
                    }
                    .navigationTitle("Top Artists")
            } else {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
