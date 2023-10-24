//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI

struct TabUIView: View {
    @Binding var isLoggedIn: Bool = true
    var body: some View {
        TabView {
            
        }.accentColor(.white)
    }
}

#Preview {
    TabUIView()
}
