# Spotify Deep Linking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-width "Open in Spotify" green button to SongDetailView, ArtistDetailView, and AlbumDetailView that opens the item in the Spotify app (or Safari if Spotify is not installed).

**Architecture:** Each detail view already receives `spotifyId: String`. The button constructs an `https://open.spotify.com/{type}/{spotifyId}` universal link and calls `UIApplication.shared.open()`. iOS routes universal links to the Spotify app when installed and falls back to Safari when not — no explicit fallback code is needed.

**Tech Stack:** Swift, SwiftUI, UIKit (`UIApplication.shared.open`), Xcode iOS Simulator (iPhone 17)

---

### Task 1: Add "Open in Spotify" button to SongDetailView

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift`

**Context:** `SongDetailView` fetches a track from `/v1/tracks/{id}` and shows metadata. `spotifyId` is the Spotify track ID. The button must only render inside the `if let song = song` branch, after the metadata `VStack` and before `Spacer()`.

- [ ] **Step 1: Add `import UIKit`**

Open `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift`. Add `import UIKit` on the line after `import SwiftUI`:

```swift
import SwiftUI
import UIKit
```

- [ ] **Step 2: Add the button**

Find the closing `}` of the `VStack(alignment: .leading, spacing: 12)` block that contains the `DetailRow` items. Add the button immediately after it, before `Spacer()`. The full `if let song = song` VStack should read:

```swift
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: song.album.images.first?.url ?? "")) { image in
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

                    Text(song.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: song.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Album", value: song.album.name)
                        DetailRow(label: "Release Date", value: song.album.releaseDate)
                        DetailRow(label: "Duration", value: formatDuration(ms: song.durationMs))
                        DetailRow(label: "Popularity", value: "\(song.popularity)/100")
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Button("Open in Spotify") {
                        if let url = URL(string: "https://open.spotify.com/track/\(spotifyId)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.114, green: 0.725, blue: 0.329))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Spacer()
                }
```

- [ ] **Step 3: Run tests to verify no regressions**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  2>&1 | tail -20
```

Expected: all existing tests pass, no build errors.

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift"
git commit -m "feat: add Open in Spotify button to SongDetailView"
```

---

### Task 2: Add "Open in Spotify" button to ArtistDetailView

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift`

**Context:** `ArtistDetailView` fetches an artist from `/v1/artists/{id}` and shows metadata. `spotifyId` is the Spotify artist ID. The button must only render inside the `if let artist = artist` branch, after the metadata `VStack` and before `Spacer()`.

- [ ] **Step 1: Add `import UIKit`**

Open `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift`. Add `import UIKit` on the line after `import SwiftUI`:

```swift
import SwiftUI
import UIKit
```

- [ ] **Step 2: Add the button**

Find the closing `}` of the `VStack(alignment: .leading, spacing: 12)` block that contains the `DetailRow` items. Add the button immediately after it, before `Spacer()`. The full `if let artist = artist` VStack should read:

```swift
                VStack(alignment: .leading, spacing: 20) {
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

                    Text(artist.name)
                        .font(.largeTitle)
                        .bold()

                    Divider()

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

                    Button("Open in Spotify") {
                        if let url = URL(string: "https://open.spotify.com/artist/\(spotifyId)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.114, green: 0.725, blue: 0.329))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Spacer()
                }
```

- [ ] **Step 3: Run tests to verify no regressions**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  2>&1 | tail -20
```

Expected: all existing tests pass, no build errors.

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift"
git commit -m "feat: add Open in Spotify button to ArtistDetailView"
```

---

### Task 3: Add "Open in Spotify" button to AlbumDetailView

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`

**Context:** `AlbumDetailView` takes `spotifyId: String`, `rank: Int?`, and `songCount: Int?`. It fetches album details from `/v1/albums/{id}` via `userTopItems.getAlbum(id:)`. The button must only render inside the `if let album = album` branch, after the metadata `VStack` and before `Spacer()`. The metadata VStack includes "Songs in Your Top 50" and "Rank" rows added in the previous album ranking feature.

- [ ] **Step 1: Add `import UIKit`**

Open `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`. Add `import UIKit` on the line after `import SwiftUI`:

```swift
import SwiftUI
import UIKit
```

- [ ] **Step 2: Add the button**

Find the closing `}` of the `VStack(alignment: .leading, spacing: 12)` block that contains the `DetailRow` items (Release Date, Total Tracks, Label, Popularity, Songs in Your Top 50, Rank). Add the button immediately after it, before `Spacer()`. The full `if let album = album` VStack should read:

```swift
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
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

                    Text(album.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: album.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Release Date", value: album.releaseDate)
                        if let totalTracks = album.totalTracks {
                            DetailRow(label: "Total Tracks", value: "\(totalTracks)")
                        }
                        if let label = album.label {
                            DetailRow(label: "Label", value: label)
                        }
                        if let popularity = album.popularity {
                            DetailRow(label: "Popularity", value: "\(popularity)/100")
                        }
                        if let songCount = songCount {
                            DetailRow(label: "Songs in Your Top 50", value: "\(songCount)")
                        }
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Button("Open in Spotify") {
                        if let url = URL(string: "https://open.spotify.com/album/\(spotifyId)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.114, green: 0.725, blue: 0.329))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Spacer()
                }
```

- [ ] **Step 3: Run tests to verify no regressions**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  2>&1 | tail -20
```

Expected: all existing tests pass, no build errors.

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift"
git commit -m "feat: add Open in Spotify button to AlbumDetailView"
```
