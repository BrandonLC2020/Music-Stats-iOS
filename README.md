# Music-Stats-iOS

A Swift-based iOS application that uses Spotify's Web API to retrieve a user’s top songs and artists over the past month, 6 months, and several years. Built in Xcode, this app provides Spotify users with insights into their listening habits and favorite music.

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Configuration](#configuration)
6. [License](#license)

## Introduction

Music-Stats-iOS leverages Spotify's Web API to allow users to gain insights into their music listening history. By providing access to top songs and artists across different time ranges, users can discover trends in their music preferences and see their all-time favorite tracks and musicians.

## Features

- Retrieve top songs and artists from Spotify for the last month, last 6 months, and all-time.
- Built using Swift in Xcode for a native, responsive iOS experience.
- Clean, intuitive interface with a focus on Spotify integration and data visualization.

## Installation

### Prerequisites
1. [Xcode](https://developer.apple.com/xcode/) (Version X.X or higher).
2. [Spotify Developer Account](https://developer.spotify.com/dashboard/) to create an application for API access.

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/username/Music-Stats-iOS.git
   cd Music-Stats-iOS
   ```
2. Open the project in Xcode:
   ```bash
   open Music-Stats-iOS.xcodeproj
   ```
3. Follow the configuration instructions below to set up Spotify credentials.

## Usage

1. Launch the app on an iOS simulator or device.
2. Log in with your Spotify account to grant access.
3. Choose a time range (last month, last 6 months, all-time) to view your top tracks and artists.
4. Explore and interact with your personalized music statistics!

## Configuration

To configure the app for use with Spotify's Web API:

1. Duplicate the `Sample.xcconfig` file and rename it to `Config.xcconfig`.
2. Open `Config.xcconfig` and fill in the following variables with your Spotify Developer credentials:
   ```plaintext
   SPOTIFY_API_CLIENT_ID=your_spotify_client_id
   SPOTIFY_API_CLIENT_SECRET=your_spotify_client_secret
   ```
3. Follow Spotify’s [Authorization Guide](https://developer.spotify.com/documentation/general/guides/authorization-guide/) to obtain access tokens.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.