# Standardize Loading & Error UI States — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `ViewState` enum + `StateContainerView` and wire all three tab views through it so loading, error, and empty states are consistent and retryable.

**Architecture:** Add a `@Published var fetchState: ViewState` to `UserTopItems`; a new `fetchAll()` method coordinates both fetch operations and sets state; a generic `StateContainerView<Content>` switches on `fetchState` and renders the appropriate UI. Each tab view becomes a thin shell around `StateContainerView`.

**Tech Stack:** Swift 5.9, SwiftUI, Apple `Testing` framework (`@Suite`/`@Test`/`#expect`), `URLSession` completion handlers, `DispatchGroup`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Music Stats iOS/Music Stats iOS/Types/ViewState.swift` | `ViewState` enum |
| Create | `Music Stats iOS/Music Stats iOS/StateContainerView.swift` | Generic state-switching container view |
| Modify | `Music Stats iOS/Music Stats iOS/UserTopItems.swift` | Add `fetchState`, `fetchAll()`, `retry()`; update `reset()` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift` | Call `fetchAll()` instead of separate fetch calls |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/TopSongsView.swift` | Wrap content in `StateContainerView` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/TopArtistsView.swift` | Wrap content in `StateContainerView` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift` | Wrap content in `StateContainerView`; resolve `.empty` state |
| Modify | `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift` | Add `fetchState` and `retry()` unit tests |

---

## Task 1: Create `ViewState` Enum

**Files:**
- Create: `Music Stats iOS/Music Stats iOS/Types/ViewState.swift`

No TDD here — this is a pure type definition with nothing to test independently.

- [ ] **Step 1: Create the file**

```swift
// ViewState.swift

enum ViewState: Equatable {
    case loading
    case content
    case error
    case empty
}
```

Save to: `Music Stats iOS/Music Stats iOS/Types/ViewState.swift`

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Types/ViewState.swift"
git commit -m "feat: add ViewState enum for loading/content/error/empty states"
```

---

## Task 2: Add `fetchState` to `UserTopItems` (TDD)

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`
- Modify: `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`

- [ ] **Step 1: Write failing test**

In `MusicStatsiOSTests.swift`, add to the existing `UserTopItemsTests` suite (after the closing brace of `resetClearsAllData`):

```swift
@Test("fetchState starts as .loading")
func fetchStateInitiallyLoading() {
    let sut = UserTopItems()
    #expect(sut.fetchState == .loading)
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|failed|passed|FAILED|PASSED"
```

Expected: compile error — `UserTopItems` has no member `fetchState`.

- [ ] **Step 3: Add `fetchState` to `UserTopItems`**

In `UserTopItems.swift`, add the property after the existing `@Published` properties (line 16, after `var userProfile`):

```swift
@Published var fetchState: ViewState = .loading
```

`init()` requires no change — the default value `.loading` handles initialization.

- [ ] **Step 4: Run tests to confirm they pass**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed|BUILD"
```

Expected: all tests pass including the new `fetchStateInitiallyLoading` test.

- [ ] **Step 5: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift" \
        "Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift"
git commit -m "feat: add fetchState to UserTopItems, initially .loading"
```

---

## Task 3: Update `reset()` to Clear `fetchState` (TDD)

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`
- Modify: `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`

- [ ] **Step 1: Write failing test**

Add to the `UserTopItemsTests` suite in `MusicStatsiOSTests.swift`:

```swift
@Test("reset() sets fetchState back to .loading")
func resetClearsFetchState() async throws {
    let sut = UserTopItems()
    sut.fetchState = .error
    sut.reset()
    // reset() dispatches to main queue; wait for it to execute
    try await Task.sleep(for: .milliseconds(100))
    #expect(sut.fetchState == .loading)
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "resetClearsFetchState|failed|passed"
```

Expected: `resetClearsFetchState` fails — `fetchState` stays `.error` after `reset()`.

- [ ] **Step 3: Update `reset()` to clear `fetchState`**

In `UserTopItems.swift`, the existing `reset()` body is:

```swift
func reset() {
    DispatchQueue.main.async {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.topAlbumsList = [:]
        self.userProfile = nil
        self.accessToken = ""
        self.tokenType = ""
    }
}
```

Replace it with:

```swift
func reset() {
    DispatchQueue.main.async {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.topAlbumsList = [:]
        self.userProfile = nil
        self.accessToken = ""
        self.tokenType = ""
        self.fetchState = .loading
    }
}
```

- [ ] **Step 4: Run tests to confirm all pass**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed|BUILD"
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift" \
        "Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift"
git commit -m "feat: reset() now clears fetchState back to .loading"
```

---

## Task 4: Add `fetchAll()` and `retry()` to `UserTopItems` (TDD)

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`
- Modify: `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`

- [ ] **Step 1: Write failing test for `retry()`**

Add to the `UserTopItemsTests` suite in `MusicStatsiOSTests.swift`:

```swift
@Test("retry() immediately sets fetchState to .loading")
func retrySetsFetchStateToLoading() {
    let sut = UserTopItems()
    sut.fetchState = .error
    sut.retry()
    #expect(sut.fetchState == .loading)
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "retrySetsFetchState|error:|failed"
```

Expected: compile error — `UserTopItems` has no member `retry`.

- [ ] **Step 3: Add `fetchAll()` and `retry()` to `UserTopItems`**

Add these two methods to `UserTopItems.swift`, after the existing `getTopArtists` method and before `calculateTopAlbums`:

```swift
func fetchAll() {
    let group = DispatchGroup()

    group.enter()
    getTopSongs { group.leave() }

    group.enter()
    getTopArtists { group.leave() }

    group.notify(queue: .main) {
        let songsLoaded = self.topSongsList.count == 3
        let artistsLoaded = self.topArtistsList.count == 3
        self.fetchState = (songsLoaded && artistsLoaded) ? .content : .error
    }
}

func retry() {
    // Called from main thread via SwiftUI action.
    // Does NOT clear accessToken/tokenType — those are needed for re-fetching.
    fetchState = .loading
    topSongsResponse = [:]
    topArtistsResponse = [:]
    topSongsList = [:]
    topArtistsList = [:]
    topAlbumsList = [:]
    getUserProfile {}
    fetchAll()
}
```

- [ ] **Step 4: Run tests to confirm all pass**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed|BUILD"
```

Expected: all tests pass including `retrySetsFetchStateToLoading`.

- [ ] **Step 5: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift" \
        "Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift"
git commit -m "feat: add fetchAll() and retry() to UserTopItems"
```

---

## Task 5: Update `TabUIView` to Use `fetchAll()`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift`

- [ ] **Step 1: Replace separate fetch calls with `fetchAll()`**

The current `.onAppear` in `TabUIView.swift` is:

```swift
.onAppear {
    if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
        userTopItems.accessToken = accessToken
        userTopItems.tokenType = tokenType
        userTopItems.getUserProfile {}
        userTopItems.getTopSongs {}
        userTopItems.getTopArtists {}
    }
}
```

Replace it with:

```swift
.onAppear {
    if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
        userTopItems.accessToken = accessToken
        userTopItems.tokenType = tokenType
        userTopItems.getUserProfile {}
        userTopItems.fetchAll()
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift"
git commit -m "feat: TabUIView uses fetchAll() to coordinate fetch + error state"
```

---

## Task 6: Create `StateContainerView`

**Files:**
- Create: `Music Stats iOS/Music Stats iOS/StateContainerView.swift`

- [ ] **Step 1: Create the file**

```swift
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
```

Save to: `Music Stats iOS/Music Stats iOS/StateContainerView.swift`

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/StateContainerView.swift"
git commit -m "feat: add StateContainerView for loading/error/empty/content states"
```

---

## Task 7: Refactor `TopSongsView`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/TopSongsView.swift`

- [ ] **Step 1: Replace the full file contents**

The new `TopSongsView.swift`:

```swift
// TopSongsView.swift

import SwiftUI

struct TopSongsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedSong: Song?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: userTopItems.fetchState,
                loadingLabel: "Loading Songs…",
                emptySymbol: "music.note",
                emptyTitle: "No Top Songs Found",
                emptyDescription: "",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(songsForSelection() ?? []) { song in
                            Button {
                                selectedSong = song
                            } label: {
                                SongCard(song: song)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(song.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
            }
            .navigationDestination(item: $selectedSong) { song in
                SongDetailView(spotifyId: song.spotifyId, rank: song.rank)
            }
            .navigationTitle("Top Songs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Time Period", selection: $selection) {
                            Text("Past Month").tag(0)
                            Text("Past 6 Months").tag(1)
                            Text("Past Years").tag(2)
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                ProfileToolbarItem()
            }
        }
    }

    private func songsForSelection() -> [Song]? {
        switch selection {
        case 0: return userTopItems.topSongsList["short"]
        case 1: return userTopItems.topSongsList["medium"]
        case 2: return userTopItems.topSongsList["long"]
        default: return nil
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Songs/TopSongsView.swift"
git commit -m "feat: TopSongsView uses StateContainerView for loading/error states"
```

---

## Task 8: Refactor `TopArtistsView`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/TopArtistsView.swift`

- [ ] **Step 1: Replace the full file contents**

The new `TopArtistsView.swift`:

```swift
// TopArtistsView.swift

import SwiftUI

struct TopArtistsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedArtist: Artist?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: userTopItems.fetchState,
                loadingLabel: "Loading Artists…",
                emptySymbol: "music.mic",
                emptyTitle: "No Top Artists Found",
                emptyDescription: "",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(artistsForSelection() ?? []) { artist in
                            Button {
                                selectedArtist = artist
                            } label: {
                                ArtistCard(artist: artist)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(artist.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
            }
            .navigationDestination(item: $selectedArtist) { artist in
                ArtistDetailView(spotifyId: artist.spotifyId, rank: artist.rank)
            }
            .navigationTitle("Top Artists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Time Period", selection: $selection) {
                            Text("Past Month").tag(0)
                            Text("Past 6 Months").tag(1)
                            Text("Past Years").tag(2)
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                ProfileToolbarItem()
            }
        }
    }

    private func artistsForSelection() -> [Artist]? {
        switch selection {
        case 0: return userTopItems.topArtistsList["short"]
        case 1: return userTopItems.topArtistsList["medium"]
        case 2: return userTopItems.topArtistsList["long"]
        default: return nil
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Artists/TopArtistsView.swift"
git commit -m "feat: TopArtistsView uses StateContainerView for loading/error states"
```

---

## Task 9: Refactor `TopAlbumsView`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift`

This is the most complex tab because Albums can reach the `.empty` state. A computed `resolvedState` property handles the override.

- [ ] **Step 1: Replace the full file contents**

The new `TopAlbumsView.swift`:

```swift
// TopAlbumsView.swift

import SwiftUI

struct TopAlbumsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedAlbum: Album?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: resolvedState,
                loadingLabel: "Calculating Top Albums…",
                emptySymbol: "music.note.list",
                emptyTitle: "No Top Albums Found",
                emptyDescription: "We rank albums based on how many of your top 50 songs are from the same album. " +
                                  "Listen to more songs from the same album to see them here!",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(albumsForSelection() ?? []) { album in
                            Button {
                                selectedAlbum = album
                            } label: {
                                AlbumCard(album: album)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(album.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
            }
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(spotifyId: album.spotifyId ?? "", rank: album.rank)
            }
            .navigationTitle("Top Albums")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                timeframeToolbar
                ProfileToolbarItem()
            }
        }
    }

    private var resolvedState: ViewState {
        guard userTopItems.fetchState == .content else { return userTopItems.fetchState }
        let albums = albumsForSelection() ?? []
        return albums.isEmpty ? .empty : .content
    }

    private var timeframeToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Picker("Time Period", selection: $selection) {
                    Text("Past Month").tag(0)
                    Text("Past 6 Months").tag(1)
                    Text("Past Years").tag(2)
                }
            } label: {
                Image(systemName: "calendar")
            }
        }
    }

    private func albumsForSelection() -> [Album]? {
        switch selection {
        case 0: return userTopItems.topAlbumsList["short"]
        case 1: return userTopItems.topAlbumsList["medium"]
        case 2: return userTopItems.topAlbumsList["long"]
        default: return nil
        }
    }
}

struct TopAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        TopAlbumsView(userTopItems: UserTopItems())
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/TopAlbumsView.swift"
git commit -m "feat: TopAlbumsView uses StateContainerView; resolves .empty for zero albums"
```

---

## Task 10: Add SwiftUI Previews to `StateContainerView`

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/StateContainerView.swift`

Previews are the right regression check for a pure UI component — one per state so each state's appearance is immediately visible in Xcode Canvas.

- [ ] **Step 1: Add previews at the bottom of `StateContainerView.swift`**

Append to `StateContainerView.swift` (after the closing brace of the struct):

```swift
#Preview("Loading") {
    StateContainerView(
        state: .loading,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}

#Preview("Content") {
    StateContainerView(
        state: .content,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
            .font(.title)
    }
}

#Preview("Error") {
    StateContainerView(
        state: .error,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}

#Preview("Empty") {
    StateContainerView(
        state: .empty,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note.list",
        emptyTitle: "No Top Albums Found",
        emptyDescription: "We rank albums based on how many of your top 50 songs are from the same album. Listen to more songs from the same album to see them here!",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run full test suite**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed|BUILD"
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/StateContainerView.swift"
git commit -m "feat: add SwiftUI previews for all four ViewState cases"
```
