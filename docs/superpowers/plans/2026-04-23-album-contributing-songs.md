# Contributing Songs in Top Albums Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display the specific songs that contributed to an album's ranking in the Top Albums detail view.

**Architecture:** Update the `Album` model to store a list of `Song` objects, populate this during the ranking calculation, and update the UI to render these songs using existing `SongCard` components.

**Tech Stack:** Swift, SwiftUI

---

### Task 1: Update Album Model

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift`

- [ ] **Step 1: Add contributingSongs property to Album struct**

```swift
struct Album: Identifiable, Hashable {
    var id: String
    var spotifyId: String?
    var rank: Int?
    var images: [ImageResponse]
    var name: String
    var artists: [Artist]?
    var releaseDate: String
    var totalTracks: Int? = nil
    var songCount: Int? = nil
    var contributingSongs: [Song]? = nil // Add this line
}
```

- [ ] **Step 2: Commit changes**

```bash
git add "Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift"
git commit -m "feat: add contributingSongs to Album model"
```

---

### Task 2: Update Calculation Logic

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`

- [ ] **Step 1: Update calculateTopAlbums to store contributing songs**

Modify the mapping at the end of `calculateTopAlbums()`:

```swift
            self.topAlbumsList[key] = sortedGroups.enumerated().map { index, songs in
                let representative = songs.min(by: { $0.album.name.count < $1.album.name.count })!
                return Album(
                    id: "\(key)-\(index + 1)-\(representative.album.spotifyId ?? representative.album.id)",
                    spotifyId: representative.album.spotifyId,
                    rank: index + 1,
                    images: representative.album.images,
                    name: representative.album.name,
                    artists: representative.artists,
                    releaseDate: representative.album.releaseDate,
                    totalTracks: representative.album.totalTracks,
                    songCount: songs.count,
                    contributingSongs: songs // Add this line
                )
            }
```

- [ ] **Step 2: Commit changes**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift"
git commit -m "feat: populate contributingSongs during album calculation"
```

---

### Task 3: Refactor AlbumDetailView to accept Album object

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift`

- [ ] **Step 1: Update AlbumDetailView initialization**

Change the properties to accept an `Album` object instead of individual fields.

```swift
struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let albumData: Album // Replace spotifyId, rank, songCount with this

    @State private var albumResponse: AlbumResponse? // Rename from 'album' to avoid confusion
    @State private var isLoading = true

    // ... updated body will use albumData.spotifyId, etc.
}
```

- [ ] **Step 2: Update navigation in TopAlbumsView**

```swift
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(albumData: album)
            }
```

- [ ] **Step 3: Commit changes**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift" "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift"
git commit -m "refactor: pass full Album object to AlbumDetailView"
```

---

### Task 4: Implement Contributing Songs Section

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`

- [ ] **Step 1: Add the songs section to the ScrollView**

Add this below the "Open in Spotify" button in `AlbumDetailView`:

```swift
                    if let songs = albumData.contributingSongs, !songs.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Top Songs from this Album")
                                .font(.title2)
                                .bold()
                                .padding(.top, 20)

                            ForEach(songs) { song in
                                NavigationLink(destination: SongDetailView(spotifyId: song.spotifyId, rank: song.rank)) {
                                    SongCard(song: song)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
```

- [ ] **Step 2: Commit changes**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift"
git commit -m "feat: display contributing songs in AlbumDetailView"
```
