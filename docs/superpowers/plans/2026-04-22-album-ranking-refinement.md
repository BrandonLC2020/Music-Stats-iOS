# Album Ranking Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine `calculateTopAlbums()` to merge deluxe editions, rank by weighted song score, and expose `totalTracks`/`songCount` in the display model.

**Architecture:** All business logic lives in `UserTopItems.calculateTopAlbums()` and a new private `normalizeAlbumName()` helper. The `Album` display struct gains two optional fields with default values so no existing call sites change. `AlbumDetailView` receives `songCount` as a new parameter and shows it as a detail row.

**Tech Stack:** Swift, Swift Testing (`import Testing`), SwiftUI, Xcode 16, iOS Simulator iPhone 16

---

## File Map

| File | Change |
|---|---|
| `Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift` | Add `totalTracks: Int? = nil` and `songCount: Int? = nil` to `Album` |
| `Music Stats iOS/Music Stats iOS/UserTopItems.swift` | Add `normalizeAlbumName()`, rewrite `calculateTopAlbums()`, populate `totalTracks` in `getTopSongs()` |
| `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift` | Update `makeSong` helper; add `AlbumRankingRefinementTests` suite |
| `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift` | Add `songCount: Int?` parameter; add "Songs in Your Top 50" detail row |
| `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift` | Pass `album.songCount` to `AlbumDetailView` |

---

## Task 1: Add `totalTracks` and `songCount` to `Album` and populate `totalTracks` in `getTopSongs()`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift`
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`

- [ ] **Step 1: Add two optional fields with defaults to `Album`**

In `Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift`, replace:

```swift
struct Album: Identifiable, Hashable {
    var id: String
    var spotifyId: String? // Added this for consistency with other types
    var rank: Int?
    var images: [ImageResponse]
    var name: String
    var artists: [Artist]? // Added this to store album artists
    var releaseDate: String
}
```

with:

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
}
```

Swift's synthesized memberwise initializer respects default values, so all existing `Album(...)` call sites compile unchanged.

- [ ] **Step 2: Populate `totalTracks` when building `Album` inside `getTopSongs()`**

In `Music Stats iOS/Music Stats iOS/UserTopItems.swift`, inside the `getTopSongs()` method, replace the `Album(...)` construction (lines ~66–76):

```swift
let album = Album(
    id: songResponse.album.id,
    spotifyId: songResponse.album.id,
    rank: nil,
    images: songResponse.album.images,
    name: songResponse.album.name,
    artists: songResponse.artists.map {
        Artist(id: "album-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
    },
    releaseDate: songResponse.album.releaseDate
)
```

with:

```swift
let album = Album(
    id: songResponse.album.id,
    spotifyId: songResponse.album.id,
    rank: nil,
    images: songResponse.album.images,
    name: songResponse.album.name,
    artists: songResponse.artists.map {
        Artist(id: "album-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
    },
    releaseDate: songResponse.album.releaseDate,
    totalTracks: songResponse.album.totalTracks
)
```

- [ ] **Step 3: Build to confirm it compiles**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift" \
        "Music Stats iOS/Music Stats iOS/UserTopItems.swift"
git commit -m "feat: add totalTracks and songCount fields to Album display model"
```

---

## Task 2: Write failing tests for the new ranking behavior

**Files:**
- Modify: `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`

- [ ] **Step 1: Update the existing `makeSong` helper to support `artistId` and `totalTracks`**

In `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`, inside `TopAlbumsCalculationTests`, replace the existing `makeSong` helper:

```swift
private func makeSong(
    name: String,
    spotifyId: String,
    albumId: String,
    albumName: String,
    rank: Int,
    timeRange: String = "short"
) -> Song {
    let image = ImageResponse(url: "https://img.com", height: 300, width: 300)
    let album = Album(
        id: albumId, spotifyId: albumId, rank: nil,
        images: [image], name: albumName, artists: nil, releaseDate: "2023-01-01"
    )
    return Song(
        id: "\(timeRange)-\(rank)-\(spotifyId)", spotifyId: spotifyId, rank: rank,
        album: album, artists: [], durationMs: 200000, name: name, popularity: 80
    )
}
```

with:

```swift
private func makeSong(
    name: String,
    spotifyId: String,
    albumId: String,
    albumName: String,
    rank: Int,
    artistId: String = "artist-default",
    totalTracks: Int? = nil,
    timeRange: String = "short"
) -> Song {
    let image = ImageResponse(url: "https://img.com", height: 300, width: 300)
    let artist = Artist(id: "test-\(artistId)", spotifyId: artistId, name: "Artist \(artistId)")
    let album = Album(
        id: albumId, spotifyId: albumId, rank: nil,
        images: [image], name: albumName, artists: [artist],
        releaseDate: "2023-01-01", totalTracks: totalTracks
    )
    return Song(
        id: "\(timeRange)-\(rank)-\(spotifyId)", spotifyId: spotifyId, rank: rank,
        album: album, artists: [artist], durationMs: 200000, name: name, popularity: 80
    )
}
```

- [ ] **Step 2: Add a new `AlbumRankingRefinementTests` suite at the bottom of `MusicStatsiOSTests.swift`**

Append after the closing `}` of `AuthManagerTests`:

```swift
// MARK: - Album Ranking Refinement Tests

@MainActor
@Suite("Album Ranking Refinement")
struct AlbumRankingRefinementTests {

    private func makeSong(
        name: String,
        spotifyId: String,
        albumId: String,
        albumName: String,
        rank: Int,
        artistId: String = "artist-default",
        totalTracks: Int? = nil,
        timeRange: String = "short"
    ) -> Song {
        let image = ImageResponse(url: "https://img.com", height: 300, width: 300)
        let artist = Artist(id: "test-\(artistId)", spotifyId: artistId, name: "Artist \(artistId)")
        let album = Album(
            id: albumId, spotifyId: albumId, rank: nil,
            images: [image], name: albumName, artists: [artist],
            releaseDate: "2023-01-01", totalTracks: totalTracks
        )
        return Song(
            id: "\(timeRange)-\(rank)-\(spotifyId)", spotifyId: spotifyId, rank: rank,
            album: album, artists: [artist], durationMs: 200000, name: name, popularity: 80
        )
    }

    @Test("Weighted score: album with high-ranked songs beats album with more low-ranked songs")
    func weightedScoreBeatsRawCount() {
        let sut = UserTopItems()
        // Album A: 2 songs ranked #1 and #2 → score = 50 + 49 = 99
        // Album B: 3 songs ranked #48, #49, #50 → score = 3 + 2 + 1 = 6
        // Album A should win despite fewer songs
        sut.topSongsList["short"] = [
            makeSong(name: "S1", spotifyId: "s1", albumId: "albA", albumName: "Album A",
                     rank: 1, artistId: "artist1"),
            makeSong(name: "S2", spotifyId: "s2", albumId: "albA", albumName: "Album A",
                     rank: 2, artistId: "artist1"),
            makeSong(name: "S3", spotifyId: "s3", albumId: "albB", albumName: "Album B",
                     rank: 48, artistId: "artist2"),
            makeSong(name: "S4", spotifyId: "s4", albumId: "albB", albumName: "Album B",
                     rank: 49, artistId: "artist2"),
            makeSong(name: "S5", spotifyId: "s5", albumId: "albB", albumName: "Album B",
                     rank: 50, artistId: "artist2"),
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]!
        #expect(albums.count == 2)
        #expect(albums[0].name == "Album A")
        #expect(albums[1].name == "Album B")
    }

    @Test("Edition merging: deluxe and standard editions combine into one album")
    func deluxeEditionsMerged() {
        let sut = UserTopItems()
        // Songs from both "Midnights" (albA) and "Midnights (3am Edition)" (albB) by same artist
        sut.topSongsList["short"] = [
            makeSong(name: "S1", spotifyId: "s1", albumId: "albA", albumName: "Midnights",
                     rank: 5, artistId: "artist1"),
            makeSong(name: "S2", spotifyId: "s2", albumId: "albB",
                     albumName: "Midnights (3am Edition)", rank: 10, artistId: "artist1"),
            makeSong(name: "S3", spotifyId: "s3", albumId: "albA", albumName: "Midnights",
                     rank: 15, artistId: "artist1"),
            makeSong(name: "S4", spotifyId: "s4", albumId: "albB",
                     albumName: "Midnights (3am Edition)", rank: 20, artistId: "artist1"),
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]!
        #expect(albums.count == 1)
        #expect(albums[0].name == "Midnights")
    }

    @Test("songCount reflects total songs pooled across merged editions")
    func songCountAfterMerge() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "S1", spotifyId: "s1", albumId: "albA", albumName: "Midnights",
                     rank: 5, artistId: "artist1"),
            makeSong(name: "S2", spotifyId: "s2", albumId: "albB",
                     albumName: "Midnights (3am Edition)", rank: 10, artistId: "artist1"),
            makeSong(name: "S3", spotifyId: "s3", albumId: "albA", albumName: "Midnights",
                     rank: 15, artistId: "artist1"),
            makeSong(name: "S4", spotifyId: "s4", albumId: "albB",
                     albumName: "Midnights (3am Edition)", rank: 20, artistId: "artist1"),
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]!
        #expect(albums[0].songCount == 4)
    }

    @Test("totalTracks is propagated from the representative song's album data")
    func totalTracksIsPopulated() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "S1", spotifyId: "s1", albumId: "albA", albumName: "My Album",
                     rank: 1, artistId: "artist1", totalTracks: 13),
            makeSong(name: "S2", spotifyId: "s2", albumId: "albA", albumName: "My Album",
                     rank: 2, artistId: "artist1", totalTracks: 13),
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]!
        #expect(albums[0].totalTracks == 13)
    }

    @Test("Representative album uses shortest name when editions are merged")
    func representativeAlbumHasShortestName() {
        let sut = UserTopItems()
        // Both editions should merge; "Folklore" is shorter than "Folklore (Deluxe Version)"
        sut.topSongsList["short"] = [
            makeSong(name: "S1", spotifyId: "s1", albumId: "albB",
                     albumName: "Folklore (Deluxe Version)", rank: 1, artistId: "artist1"),
            makeSong(name: "S2", spotifyId: "s2", albumId: "albB",
                     albumName: "Folklore (Deluxe Version)", rank: 2, artistId: "artist1"),
            makeSong(name: "S3", spotifyId: "s3", albumId: "albA", albumName: "Folklore",
                     rank: 3, artistId: "artist1"),
            makeSong(name: "S4", spotifyId: "s4", albumId: "albA", albumName: "Folklore",
                     rank: 4, artistId: "artist1"),
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]!
        #expect(albums.count == 1)
        #expect(albums[0].name == "Folklore")
    }
}
```

- [ ] **Step 3: Run tests to confirm the new tests fail**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(Test Case|FAILED|passed|failed)" | tail -20
```

Expected: The 5 new tests in `AlbumRankingRefinementTests` fail. The existing `TopAlbumsCalculationTests` tests should still pass (their results are unchanged by the new algorithm).

---

## Task 3: Implement `normalizeAlbumName()` and rewrite `calculateTopAlbums()`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`

- [ ] **Step 1: Add `normalizeAlbumName()` private helper**

At the bottom of `UserTopItems.swift`, before the closing `}` of the `// MARK: - Individual Item Fetching` extension, add a new extension:

```swift
// MARK: - Album Name Normalization

extension UserTopItems {
    private func normalizeAlbumName(_ name: String) -> String {
        let pattern = #"\s*[(\[][^)\]]*?(?:deluxe|edition|remaster(?:ed)?|bonus|special|anniversary|expanded|platinum|collector|3am)[^)\]]*[)\]]"#
        return name
            .replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
    }
}
```

The regex matches any parenthetical or bracketed suffix containing a known edition keyword (case-insensitive), strips it, then lowercases the result. This produces the grouping key — the actual display name still comes from the raw album name.

- [ ] **Step 2: Replace `calculateTopAlbums()` with the new implementation**

In `Music Stats iOS/Music Stats iOS/UserTopItems.swift`, replace the entire `calculateTopAlbums()` method:

```swift
func calculateTopAlbums() {
    let keys = ["short", "medium", "long"]
    for key in keys {
        guard let songs = topSongsList[key] else {
            self.topAlbumsList[key] = []
            continue
        }

        var groupToSongs: [String: [Song]] = [:]
        for song in songs {
            let normalizedName = normalizeAlbumName(song.album.name)
            let primaryArtistId = song.artists.first?.spotifyId ?? "unknown"
            let groupKey = "\(normalizedName)||\(primaryArtistId)"
            groupToSongs[groupKey, default: []].append(song)
        }

        let filteredGroups = groupToSongs.values.filter { $0.count > 1 }

        let sortedGroups = filteredGroups.sorted { songs1, songs2 in
            let score1 = songs1.reduce(0) { $0 + (51 - ($1.rank ?? 51)) }
            let score2 = songs2.reduce(0) { $0 + (51 - ($1.rank ?? 51)) }
            return score1 > score2
        }

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
                songCount: songs.count
            )
        }
    }
}
```

`★ Insight ─────────────────────────────────────`
The weighted score `(51 - rank)` encodes both song count and song quality in a single integer. Adding more songs always increases the score, but so does having higher-ranked songs. This replaces a two-key sort with a one-key sort, which is simpler to reason about and easier to test.
`─────────────────────────────────────────────────`

- [ ] **Step 3: Run all tests to verify both old and new tests pass**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(Test Suite|passed|failed)" | tail -10
```

Expected: All suites pass. Look for the `AlbumRankingRefinementTests` suite showing 5 tests passed.

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift" \
        "Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift"
git commit -m "feat: weighted score ranking and edition merging for top albums (86b9gcvu2)"
```

---

## Task 4: Update `AlbumDetailView` and `TopAlbumsView` to display `songCount`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift`

- [ ] **Step 1: Add `songCount` parameter to `AlbumDetailView`**

In `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`, replace:

```swift
struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var album: AlbumResponse?
    @State private var isLoading = true
```

with:

```swift
struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?
    let songCount: Int?

    @State private var album: AlbumResponse?
    @State private var isLoading = true
```

- [ ] **Step 2: Add "Songs in Your Top 50" detail row**

In the same file, inside the `VStack` of detail rows, replace:

```swift
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
```

with:

```swift
                        if let songCount = songCount {
                            DetailRow(label: "Songs in Your Top 50", value: "\(songCount)")
                        }
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
```

- [ ] **Step 3: Pass `songCount` from `TopAlbumsView`**

In `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift`, replace:

```swift
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(spotifyId: album.spotifyId ?? "", rank: album.rank)
            }
```

with:

```swift
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(spotifyId: album.spotifyId ?? "", rank: album.rank, songCount: album.songCount)
            }
```

- [ ] **Step 4: Build to confirm no compile errors**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Run full test suite one final time**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(Test Suite|passed|failed)" | tail -10
```

Expected: All test suites pass.

- [ ] **Step 6: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift" \
        "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift"
git commit -m "feat: show Songs in Your Top 50 count in AlbumDetailView"
```
