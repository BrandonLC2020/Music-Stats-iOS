# Music-Stats-iOS

Music-Stats-iOS is a Swift-based iOS application that leverages the Spotify Web API to provide users with insightful statistics about their listening habits. Discover your top songs and artists across various timeframes and get a clearer picture of your musical journey.

## Introduction

Have you ever wondered what your most-played songs and artists are over the last month, six months, or even several years? Music-Stats-iOS connects securely to your Spotify account to fetch and display this information in a clean, intuitive, and native iOS interface. This app is perfect for music enthusiasts who want to delve deeper into their listening patterns and rediscover their favorite tunes.

## Features

  * **Secure Spotify Authentication:** Utilizes a secure OAuth 2.0 flow to connect to your Spotify account.
  * **Top Songs and Artists:** View your top 50 songs and artists from three different time ranges:
      * Last Month (short\_term)
      * Last 6 Months (medium\_term)
      * All Time (long\_term)
  * **Detailed Information:** See details like album art, artist names, and release dates for songs, and view artist images.
  * **Native iOS Experience:** Built with SwiftUI for a responsive and modern user experience.
  * **Persistent Login:** Securely stores your refresh token in the keychain, so you don't have to log in every time you open the app.

## How It Works

1.  **Authorization:** The app initiates an authorization request to the Spotify API.
2.  **User Login:** You will be prompted to log in to your Spotify account and grant permission for the app to access your top artists and tracks.
3.  **Token Exchange:** Upon successful authorization, the app receives an authorization code, which it then exchanges for an access token and a refresh token.
4.  **API Requests:** The access token is used to make secure requests to the Spotify API to fetch your top songs and artists.
5.  **Data Display:** The fetched data is then parsed and displayed in the app's user-friendly interface.
6.  **Token Refresh:** The refresh token is securely stored in the device's keychain and is used to obtain a new access token when the current one expires, ensuring a seamless user experience.

## Technologies Used

  * **Swift & SwiftUI:** The application is built entirely in Swift, using SwiftUI for the user interface.
  * **Spotify Web API:** All music data is retrieved from the official Spotify Web API.
  * **Keychain-Swift:** A third-party library used for securely storing the Spotify refresh token in the keychain.
  * **Xcode:** Developed and built using Xcode.

## Installation

### Prerequisites

1.  [Xcode](https://developer.apple.com/xcode/) (Version 15.0 or higher)
2.  A [Spotify Developer Account](https://developer.spotify.com/dashboard/) to create an application for API access.

### Steps

1.  Clone the repository:
    ```bash
    git clone https://github.com/brandonlc2020/music-stats-ios.git
    cd Music-Stats-iOS
    ```
2.  Open the project in Xcode:
    ```bash
    open "Music Stats iOS.xcodeproj"
    ```
3.  Follow the configuration instructions below to set up your Spotify API credentials.

## Configuration

To use the Spotify Web API, you'll need to provide your own client ID and client secret.

1.  In the `Music Stats iOS` directory, duplicate the `Sample.xcconfig` file and rename it to `Config.xcconfig`.
2.  Open `Config.xcconfig` and add your Spotify Developer credentials and a redirect URI:
    ```
    SPOTIFY_API_CLIENT_ID = your_spotify_client_id
    SPOTIFY_API_CLIENT_SECRET = your_spotify_client_secret
    REDIRECT_URI_SCHEME = your_app_redirect_scheme 
    REDIRECT_URI_HOST = your_app_redirect_host 
    ```
3.  In your Spotify Developer Dashboard, make sure to add the redirect URI you specified in the `Config.xcconfig` file to your application's settings. For example: `your_app_redirect_scheme://your_app_redirect_host`.
4.  Build and run the app.

## Usage

1.  Launch the app on an iOS simulator or a physical device.
2.  Tap the "Authorize" button to log in with your Spotify account.
3.  Once authenticated, you will be taken to the main screen where you can view your top songs and artists.
4.  Use the segmented control at the top to switch between different time ranges (Past Month, Past 6 Months, Past Years).

## License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
