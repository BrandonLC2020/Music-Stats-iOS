# Design Doc: Contributing Songs in Top Albums Detail View

Show the specific songs from the user's top songs list that contributed to an album being ranked as a "Top Album" in the album detail view.

## 1. Problem Statement
The app currently calculates "Top Albums" by grouping top tracks from a selected timeframe. However, the `AlbumDetailView` only displays general album metadata and doesn't show the user which specific songs from their top list are associated with that album.

## 2. Proposed Changes

### 2.1. Data Model (`IdentifiableTypes.swift`)
Update the `Album` struct to include an optional property for contributing songs.

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
    var contributingSongs: [Song]? = nil // New property
}
```

### 2.2. Data Management (`UserTopItems.swift`)
Modify `calculateTopAlbums()` to populate the `contributingSongs` property when creating `Album` objects.

- During the grouping phase, we already have the `[Song]` array for each album group.
- When mapping these groups to the final `topAlbumsList`, assign the filtered and sorted songs to the `contributingSongs` property.

### 2.3. User Interface (`AlbumDetailView.swift`)
Enhance the detail view to display the contributing songs.

- Add a new section below the metadata called "Top Songs from this Album".
- Use a `VStack` or `LazyVStack` to list the songs.
- Render each song using the existing `SongCard` component for visual consistency.
- Add a `NavigationLink` to `SongDetailView` for each song.

## 3. Architecture & Data Flow
1. **Fetch:** App fetches top tracks from Spotify.
2. **Calculate:** `UserTopItems` groups tracks into albums and identifies "contributing tracks".
3. **Store:** `Album` objects now carry their own specific list of top tracks.
4. **Display:** `AlbumDetailView` iterates over `album.contributingSongs` and displays them.

## 4. Error Handling & Edge Cases
- **No songs:** If `contributingSongs` is empty or nil, the section will not be displayed.
- **Loading:** Songs are available immediately as they are part of the `Album` object passed from the list view (or fetched as part of the initial calculation).

## 5. Testing Strategy
- **Manual Verification:**
    - Navigate to "Top Albums".
    - Select an album.
    - Verify that the list of songs matches the number indicated in "Songs in Your Top 50".
    - Verify that tapping a song navigates correctly to its detail view.
- **Logic Check:** Ensure the normalization logic correctly groups songs even if their album names have slight variations (handled by existing `normalizeAlbumName`).
