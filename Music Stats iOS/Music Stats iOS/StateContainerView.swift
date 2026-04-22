// StateContainerView.swift

import SwiftUI

struct StateContainerView<Content: View>: View {
    let state: ViewState
    let loadingLabel: String
    let emptySymbol: String
    let emptyTitle: String
    let emptyDescription: String
    let onRetry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            VStack {
                ProgressView(loadingLabel)
            }
        case .content:
            content()
        case .error:
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Something went wrong")
                    .font(.title2)
                    .bold()
                Button("Tap to Retry", action: onRetry)
                    .buttonStyle(.bordered)
            }
            .padding()
        case .empty:
            VStack(spacing: 20) {
                Image(systemName: emptySymbol)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text(emptyTitle)
                    .font(.title2)
                    .bold()
                Text(emptyDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}
