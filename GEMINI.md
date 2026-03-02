# Music-Stats-iOS Project Overview

Music-Stats-iOS is a SwiftUI-based application that provides users with insights into their Spotify listening habits. It fetches top songs and artists from the Spotify Web API and calculates top albums locally.

## Project Structure

- **`Music Stats iOS/Music Stats iOS/`**: Main source code directory.
  - **`Music_Stats_iOSApp.swift`**: App entry point, manages authentication state and main view navigation.
  - **`AuthManager.swift`**: Handles Spotify OAuth2 flow, token exchange, and persistent storage using `KeychainSwift`.
  - **`UserTopItems.swift`**: Primary data manager that fetches user profile, top songs, and artists. It also implements the logic for calculating top albums.
  - **`Tabs/`**: Contains the main view components for each tab (Songs, Albums, Artists).
  - **`Types/`**: Defines `Codable` models for API responses and internal `Identifiable` models.

## Key Technologies

- **Swift & SwiftUI**: UI development.
- **Spotify Web API**: Source for music data.
- **Keychain-Swift**: Secure storage for refresh tokens.
- **Xcode Configuration (`.xcconfig`)**: Used for managing API credentials and redirect URIs.

## Building and Running

### Prerequisites

- macOS with Xcode 15.0+ installed.
- A Spotify Developer account and an application created in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/).

### Configuration

The project requires a `Config.xcconfig` file for API credentials.
1. Duplicate `Music Stats iOS/Music Stats iOS/Sample.xcconfig` to `Music Stats iOS/Music Stats iOS/Config.xcconfig`.
2. Fill in your credentials:
   ```
   SPOTIFY_API_CLIENT_ID = your_client_id
   SPOTIFY_API_CLIENT_SECRET = your_client_secret
   REDIRECT_URI_SCHEME = your_app_scheme
   REDIRECT_URI_HOST = your_app_host
   ```
3. Ensure the redirect URI is registered in your Spotify Developer Dashboard (e.g., `scheme://host`).

### Commands

- **Build**: Open `Music Stats iOS.xcodeproj` in Xcode and press `Cmd+B`, or use:
  ```bash
  xcodebuild build -project "Music Stats iOS.xcodeproj" -scheme "Music Stats iOS" -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
- **Run**: Use Xcode to run on a simulator or physical device.
- **Test**: `Cmd+U` in Xcode, or use:
  ```bash
  xcodebuild test -project "Music Stats iOS.xcodeproj" -scheme "Music Stats iOS" -destination 'platform=iOS Simulator,name=iPhone 15'
  ```

## Development Conventions

- **State Management**: Uses `@StateObject` and `@Published` within `ObservableObject` classes (e.g., `AuthManager`, `UserTopItems`) to manage app-wide state.
- **API Communication**: Utilizes `URLSession` for network requests and `JSONDecoder` for parsing Spotify API responses.
- **Secure Storage**: Always use `AuthManager` (backed by `KeychainSwift`) to handle sensitive tokens.
- **UI Architecture**: Standard SwiftUI View hierarchy with data driven by observed objects.
- **Album Ranking Logic**: Since Spotify lacks a "top albums" endpoint, the app ranks albums based on the number of tracks appearing in the user's top 50 songs.
