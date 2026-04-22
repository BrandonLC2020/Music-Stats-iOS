# Async/Await Networking Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all completion-handler-based networking in `UserTopItems` and `AuthManager` with `async/await`, eliminate all `DispatchGroup` and `DispatchQueue.main.async` usage, and update views to use the `.task` modifier.

**Architecture:** Both `UserTopItems` and `AuthManager` are annotated `@MainActor`, making every `@Published` write automatically thread-safe without any manual dispatch. Network I/O uses `URLSession.data(for:)` (the built-in async variant), which suspends the caller without blocking the main thread. Fan-out over three time ranges uses `async let` instead of `DispatchGroup`.

**Tech Stack:** Swift 5.9+, SwiftUI, URLSession async/await, Apple Testing framework (`@Suite`/`@Test`/`#expect`)

---

## File Map

| Action | File |
|--------|------|
| Create | `Music Stats iOS/Music Stats iOS/Types/NetworkError.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/AuthManager.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/UserTopItems.swift` |
| Modify | `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift` |
| Modify | `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift` |

---

## Context: How the Xcode Project Works

This is a pure Xcode project with no Swift Package Manager or Makefile. All Swift files must be **registered in `project.pbxproj`** to be compiled. When you create a new Swift file on disk, it is NOT automatically added to the build target — you must add a `PBXFileReference` entry and a `PBXBuildFile` entry to `project.pbxproj` manually.

**Build command** (run from repo root):
```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -5
```

**Test command** (run from repo root):
```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E 'PASS|FAIL|error:|Test Suite'
```

If `name=iPhone 16` is not found, run `xcodebuild -showdestinations -project "Music Stats iOS/Music Stats iOS.xcodeproj" -scheme "Music Stats iOS"` and substitute the correct simulator name or UUID.

---

## Task 1: Create `NetworkError` enum and register in Xcode

**Files:**
- Create: `Music Stats iOS/Music Stats iOS/Types/NetworkError.swift`
- Modify: `Music Stats iOS/Music Stats iOS.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write `NetworkError.swift`**

Create the file at `Music Stats iOS/Music Stats iOS/Types/NetworkError.swift`:

```swift
enum NetworkError: Error {
    case badStatusCode(Int)
}
```

- [ ] **Step 2: Register the file in the Xcode project**

The project.pbxproj is an ASCII plist that `plutil` can convert to JSON. Run this Python script from the repo root:

```python
#!/usr/bin/env python3
import subprocess, json, uuid, os, sys

proj_path = "Music Stats iOS/Music Stats iOS.xcodeproj/project.pbxproj"

# Convert ASCII plist to JSON
result = subprocess.run(
    ['plutil', '-convert', 'json', '-o', '-', proj_path],
    capture_output=True, text=True, check=True
)
proj = json.loads(result.stdout)
objects = proj['objects']

# Generate 24-char uppercase hex UUIDs (Xcode format)
file_ref_uuid = uuid.uuid4().hex[:24].upper()
build_file_uuid = uuid.uuid4().hex[:24].upper()

# Find the "Types" PBXGroup
types_group_uuid = None
for uid, obj in objects.items():
    if obj.get('isa') == 'PBXGroup' and obj.get('name') == 'Types':
        types_group_uuid = uid
        break

if not types_group_uuid:
    print("ERROR: Could not find 'Types' group in project.pbxproj", file=sys.stderr)
    sys.exit(1)

# Add PBXFileReference
objects[file_ref_uuid] = {
    'isa': 'PBXFileReference',
    'lastKnownFileType': 'sourcecode.swift',
    'path': 'NetworkError.swift',
    'sourceTree': '<group>'
}

# Add to Types group children
objects[types_group_uuid]['children'].append(file_ref_uuid)

# Add PBXBuildFile
objects[build_file_uuid] = {
    'isa': 'PBXBuildFile',
    'fileRef': file_ref_uuid
}

# Find the PBXSourcesBuildPhase (main app target)
# There may be multiple (one for app, one for tests) — pick the one with the most files
sources_phases = {
    uid: obj for uid, obj in objects.items()
    if obj.get('isa') == 'PBXSourcesBuildPhase'
}
sources_phase_uuid = max(sources_phases, key=lambda uid: len(sources_phases[uid].get('files', [])))

objects[sources_phase_uuid]['files'].append(build_file_uuid)

# Write JSON to temp file, then convert back to XML plist
tmp = proj_path + '.tmp.json'
with open(tmp, 'w') as f:
    json.dump(proj, f)
subprocess.run(['plutil', '-convert', 'xml1', '-o', proj_path, tmp], check=True)
os.remove(tmp)

print(f"SUCCESS: NetworkError.swift registered")
print(f"  PBXFileReference: {file_ref_uuid}")
print(f"  PBXBuildFile:     {build_file_uuid}")
```

Save this as `register_network_error.py` and run:
```bash
python3 register_network_error.py
```

Expected output:
```
SUCCESS: NetworkError.swift registered
  PBXFileReference: <24-char-hex>
  PBXBuildFile:     <24-char-hex>
```

- [ ] **Step 3: Build to verify the file compiles**

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
git add "Music Stats iOS/Music Stats iOS/Types/NetworkError.swift" \
        "Music Stats iOS/Music Stats iOS.xcodeproj/project.pbxproj" \
        register_network_error.py
git commit -m "feat: add NetworkError enum for async networking"
```

---

## Task 2: Refactor `AuthManager` to `@MainActor` + async

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/AuthManager.swift`

**Background:** `AuthManager` currently uses `URLSession.dataTask` completion handlers and `DispatchQueue.main.async` for UI updates. The new version marks the class `@MainActor` (making all `@Published` writes safe by default), replaces the shared `handleTokenResponse` helper with a private `performTokenRequest(_ request: URLRequest) async` that both `refreshToken` and `exchangeCodeForTokens` call. `init()` wraps the async `refreshToken()` call in `Task {}`. `logIn(with:)` and `logout()` remain regular (non-async) functions.

- [ ] **Step 1: Replace `AuthManager.swift` with the async version**

```swift
//
//  AuthManager.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import Foundation
import KeychainSwift

@MainActor
class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    var accessToken: String?
    var tokenType: String?

    private var keychain = KeychainSwift()

    init() {
        if keychain.get("refreshToken") != nil {
            Task { await refreshToken() }
        } else {
            isLoading = false
        }
    }

    func logIn(with code: String) {
        isLoading = true
        Task { await exchangeCodeForTokens(code: code) }
    }

    func logout() {
        accessToken = nil
        tokenType = nil
        keychain.clear()
        isAuthenticated = false
    }

    func refreshToken() async {
        guard let refreshToken = keychain.get("refreshToken") else {
            isAuthenticated = false
            isLoading = false
            return
        }

        let urlRequest = createTokenURLRequest()
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }

    private func createTokenURLRequest() -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let spotifyClientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let spotifyClientSecret = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String
        let combo = "\(spotifyClientID ?? ""):\(spotifyClientSecret ?? "")"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()

        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Basic \(comboEncoded!)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        return urlRequest
    }

    private func performTokenRequest(_ request: URLRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                isAuthenticated = false
                isLoading = false
                return
            }
            if let tokenResponse = try? JSONDecoder().decode(AccessTokenResponse.self, from: data) {
                accessToken = tokenResponse.accessToken
                tokenType = tokenResponse.tokenType
                if let newRefreshToken = tokenResponse.refreshToken {
                    keychain.set(newRefreshToken, forKey: "refreshToken")
                }
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    private func exchangeCodeForTokens(code: String) async {
        let urlRequest = createTokenURLRequest()

        let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/AuthManager.swift"
git commit -m "refactor: convert AuthManager to @MainActor + async/await"
```

---

## Task 3: Refactor `UserTopItems` to `@MainActor` + async

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/UserTopItems.swift`
- Modify: `Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift`

**Background:** `UserTopItems` currently uses `URLSession.dataTask` completion handlers, `DispatchGroup` for time-range fan-out, and `DispatchQueue.main.async` for UI updates. The new version:
- Marks the class `@MainActor` — no more manual dispatch
- Primitive fetchers (`getSongsForTimeRange`, `getArtistsForTimeRange`, `getTrack`, `getArtist`, `getAlbum`) become `async throws -> T` (return value directly)
- `getUserProfile()` becomes `async` (non-throwing; failures silently skip the profile update)
- `getTopSongs()` / `getTopArtists()` become `async throws`, using `async let` for concurrent time-range fetches
- `fetchAll()` becomes `async` (non-throwing; catches internally and sets `fetchState`)
- `retry()` stays a regular function, spawning a `Task` internally
- `reset()` loses the `DispatchQueue.main.async` wrapper (direct assignment is safe with `@MainActor`)

**TDD approach:** Update the test file FIRST (add `@MainActor` to three test suites), verify tests still pass, then replace the implementation.

- [ ] **Step 1: Update `MusicStatsiOSTests.swift` — add `@MainActor` to three suites**

`UserTopItemsTests`, `TopAlbumsCalculationTests`, and `AuthManagerTests` all instantiate `@MainActor`-isolated types. `JSONDecodingTests` only tests `Codable` structs and needs no change.

Replace the entire file with:

```swift
//
//  MusicStatsiOSTests.swift
//  Music Stats iOSTests
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import Testing
import Foundation
@testable import Music_Stats_iOS

// MARK: - JSON Decoding Tests

@Suite("JSON Decoding")
struct JSONDecodingTests {

    @Test("SongResponse decodes snake_case fields correctly")
    func songResponseDecoding() throws {
        let json = """
        {
            "id": "song123",
            "name": "Test Song",
            "popularity": 85,
            "duration_ms": 210000,
            "artists": [
                { "id": "artist1", "name": "Test Artist", "popularity": 90, "genres": ["pop"] }
            ],
            "album": {
                "id": "album1",
                "name": "Test Album",
                "release_date": "2023-01-01",
                "images": [{ "url": "https://example.com/img.jpg", "height": 300, "width": 300 }]
            }
        }
        """.data(using: .utf8)!

        let song = try JSONDecoder().decode(SongResponse.self, from: json)

        #expect(song.id == "song123")
        #expect(song.name == "Test Song")
        #expect(song.popularity == 85)
        #expect(song.durationMs == 210000)
        #expect(song.artists.count == 1)
        #expect(song.artists[0].name == "Test Artist")
        #expect(song.album.name == "Test Album")
        #expect(song.album.releaseDate == "2023-01-01")
    }

    @Test("AlbumResponse decodes snake_case fields correctly")
    func albumResponseDecoding() throws {
        let json = """
        {
            "id": "album123",
            "name": "Test Album",
            "release_date": "2022-06-15",
            "images": [{ "url": "https://img.com/a.jpg", "height": 640, "width": 640 }],
            "total_tracks": 12,
            "label": "Test Label",
            "popularity": 75
        }
        """.data(using: .utf8)!

        let album = try JSONDecoder().decode(AlbumResponse.self, from: json)

        #expect(album.id == "album123")
        #expect(album.name == "Test Album")
        #expect(album.releaseDate == "2022-06-15")
        #expect(album.images.count == 1)
        #expect(album.images[0].url == "https://img.com/a.jpg")
        #expect(album.totalTracks == 12)
        #expect(album.label == "Test Label")
        #expect(album.popularity == 75)
    }

    @Test("ArtistResponse decodes correctly with optional fields")
    func artistResponseDecoding() throws {
        let json = """
        {
            "id": "artist123",
            "name": "Test Artist",
            "popularity": 88,
            "genres": ["rock", "indie"],
            "images": [{ "url": "https://img.com/artist.jpg", "height": 320, "width": 320 }]
        }
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(ArtistResponse.self, from: json)

        #expect(artist.id == "artist123")
        #expect(artist.name == "Test Artist")
        #expect(artist.popularity == 88)
        #expect(artist.genres == ["rock", "indie"])
        #expect(artist.images?.count == 1)
        #expect(artist.images?[0].url == "https://img.com/artist.jpg")
    }

    @Test("ArtistResponse handles missing optional fields")
    func artistResponseMissingOptionals() throws {
        let json = """
        {
            "id": "artist456",
            "name": "Minimal Artist"
        }
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(ArtistResponse.self, from: json)

        #expect(artist.id == "artist456")
        #expect(artist.name == "Minimal Artist")
        #expect(artist.popularity == nil)
        #expect(artist.genres == nil)
        #expect(artist.images == nil)
    }

    @Test("UserProfileResponse decodes snake_case fields correctly")
    func userProfileResponseDecoding() throws {
        let json = """
        {
            "id": "user123",
            "display_name": "Test User",
            "email": "test@example.com",
            "images": [{ "url": "https://img.com/user.jpg", "height": 200, "width": 200 }]
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(UserProfileResponse.self, from: json)

        #expect(profile.id == "user123")
        #expect(profile.displayName == "Test User")
        #expect(profile.email == "test@example.com")
        #expect(profile.images?.count == 1)
    }

    @Test("AccessTokenResponse decodes snake_case fields correctly")
    func accessTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "myAccessToken",
            "token_type": "Bearer",
            "scope": "user-top-read",
            "expires_in": 3600,
            "refresh_token": "myRefreshToken"
        }
        """.data(using: .utf8)!

        let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: json)

        #expect(tokenResponse.accessToken == "myAccessToken")
        #expect(tokenResponse.tokenType == "Bearer")
        #expect(tokenResponse.scope == "user-top-read")
        #expect(tokenResponse.expiresIn == 3600)
        #expect(tokenResponse.refreshToken == "myRefreshToken")
    }

    @Test("AccessTokenResponse handles nil refreshToken")
    func accessTokenResponseNilRefreshToken() throws {
        let json = """
        {
            "access_token": "myAccessToken",
            "token_type": "Bearer",
            "scope": "user-top-read",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: json)

        #expect(tokenResponse.refreshToken == nil)
    }

    @Test("TopSongsResponse decodes items array correctly")
    func topSongsResponseDecoding() throws {
        let json = """
        {
            "href": "https://api.spotify.com/v1/me/top/tracks",
            "limit": 50,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": 1,
            "items": [
                {
                    "id": "song1",
                    "name": "Track One",
                    "popularity": 70,
                    "duration_ms": 180000,
                    "artists": [{ "id": "a1", "name": "Artist One" }],
                    "album": {
                        "id": "alb1",
                        "name": "Album One",
                        "release_date": "2021-01-01",
                        "images": []
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TopSongsResponse.self, from: json)

        #expect(response.total == 1)
        #expect(response.limit == 50)
        #expect(response.offset == 0)
        #expect(response.next == nil)
        #expect(response.items.count == 1)
        #expect(response.items[0].name == "Track One")
        #expect(response.items[0].durationMs == 180000)
    }

    @Test("TopArtistsResponse decodes items array correctly")
    func topArtistsResponseDecoding() throws {
        let json = """
        {
            "href": "https://api.spotify.com/v1/me/top/artists",
            "limit": 50,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": 2,
            "items": [
                { "id": "a1", "name": "Artist One", "popularity": 95, "genres": ["pop"] },
                { "id": "a2", "name": "Artist Two", "popularity": 80, "genres": [] }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TopArtistsResponse.self, from: json)

        #expect(response.total == 2)
        #expect(response.items.count == 2)
        #expect(response.items[0].name == "Artist One")
        #expect(response.items[1].popularity == 80)
    }

    @Test("ImageResponse decodes all fields including optional dimensions")
    func imageResponseDecoding() throws {
        let jsonWithDimensions = """
        { "url": "https://img.com/full.jpg", "height": 640, "width": 640 }
        """.data(using: .utf8)!

        let jsonNoDimensions = """
        { "url": "https://img.com/nodims.jpg" }
        """.data(using: .utf8)!

        let withDims = try JSONDecoder().decode(ImageResponse.self, from: jsonWithDimensions)
        let noDims = try JSONDecoder().decode(ImageResponse.self, from: jsonNoDimensions)

        #expect(withDims.url == "https://img.com/full.jpg")
        #expect(withDims.height == 640)
        #expect(withDims.width == 640)

        #expect(noDims.url == "https://img.com/nodims.jpg")
        #expect(noDims.height == nil)
        #expect(noDims.width == nil)
    }
}

// MARK: - UserTopItems Tests

@MainActor
@Suite("UserTopItems")
struct UserTopItemsTests {

    @Test("Initial state has empty collections and blank tokens")
    func initialState() {
        let sut = UserTopItems()

        #expect(sut.topSongsResponse.isEmpty)
        #expect(sut.topArtistsResponse.isEmpty)
        #expect(sut.topSongsList.isEmpty)
        #expect(sut.topArtistsList.isEmpty)
        #expect(sut.topAlbumsList.isEmpty)
        #expect(sut.userProfile == nil)
        #expect(sut.accessToken == "")
        #expect(sut.tokenType == "")
    }

    @Test("reset() clears tokens and all collections")
    func resetClearsAllData() async throws {
        let sut = UserTopItems()
        let image = ImageResponse(url: "https://example.com", height: 100, width: 100)
        let album = Album(
            id: "alb1", spotifyId: "alb1", rank: 1,
            images: [image], name: "Album", artists: nil, releaseDate: "2023-01-01"
        )
        let song = Song(
            id: "short-1-song1", spotifyId: "song1", rank: 1,
            album: album, artists: [], durationMs: 180000, name: "Song", popularity: 80
        )

        sut.topSongsList["short"] = [song]
        sut.accessToken = "some-token"
        sut.tokenType = "Bearer"
        sut.userProfile = UserProfile(id: "user1", displayName: "Test User", email: nil, images: nil)

        sut.reset()

        #expect(sut.topSongsResponse.isEmpty)
        #expect(sut.topArtistsResponse.isEmpty)
        #expect(sut.topSongsList.isEmpty)
        #expect(sut.topArtistsList.isEmpty)
        #expect(sut.topAlbumsList.isEmpty)
        #expect(sut.userProfile == nil)
        #expect(sut.accessToken == "")
        #expect(sut.tokenType == "")
    }

    @Test("fetchState starts as .loading")
    func fetchStateInitiallyLoading() {
        let sut = UserTopItems()
        #expect(sut.fetchState == .loading)
    }

    @Test("reset() sets fetchState back to .loading")
    func resetClearsFetchState() {
        let sut = UserTopItems()
        sut.fetchState = .error
        sut.reset()
        #expect(sut.fetchState == .loading)
    }

    @Test("retry() immediately sets fetchState to .loading")
    func retrySetsFetchStateToLoading() {
        let sut = UserTopItems()
        sut.fetchState = .error
        sut.retry()
        #expect(sut.fetchState == .loading)
    }
}

// MARK: - Top Albums Calculation Tests

@MainActor
@Suite("Top Albums Calculation")
struct TopAlbumsCalculationTests {

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

    @Test("Albums with only one top song are excluded")
    func singleSongAlbumsExcluded() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song A", spotifyId: "s1", albumId: "alb1", albumName: "Album 1", rank: 1),
            makeSong(name: "Song B", spotifyId: "s2", albumId: "alb2", albumName: "Album 2", rank: 2),
            makeSong(name: "Song C", spotifyId: "s3", albumId: "alb3", albumName: "Album 3", rank: 3)
        ]
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.isEmpty == true)
    }

    @Test("Albums with two or more top songs are included")
    func multiSongAlbumsIncluded() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song A", spotifyId: "s1", albumId: "alb1", albumName: "Hit Album", rank: 1),
            makeSong(name: "Song B", spotifyId: "s2", albumId: "alb1", albumName: "Hit Album", rank: 2),
            makeSong(name: "Song C", spotifyId: "s3", albumId: "alb2", albumName: "Other Album", rank: 3)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 1)
        #expect(albums?[0].name == "Hit Album")
    }

    @Test("Albums sorted by song count descending, then by best rank ascending")
    func albumsSortedBySongCountThenBestRank() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Album Two", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Album Two", rank: 4),
            makeSong(name: "Song 5", spotifyId: "s5", albumId: "alb2", albumName: "Album Two", rank: 5)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 2)
        #expect(albums?[0].name == "Album Two")
        #expect(albums?[1].name == "Album One")
    }

    @Test("Albums with equal song count sorted by best song rank (lower is better)")
    func albumsWithTiedCountSortedByBestRank() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Better Album", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Better Album", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Worse Album", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Worse Album", rank: 4)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?.count == 2)
        #expect(albums?[0].name == "Better Album")
        #expect(albums?[1].name == "Worse Album")
    }

    @Test("Albums are assigned sequential ranks starting from 1")
    func albumsAssignedSequentialRanks() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2),
            makeSong(name: "Song 3", spotifyId: "s3", albumId: "alb2", albumName: "Album Two", rank: 3),
            makeSong(name: "Song 4", spotifyId: "s4", albumId: "alb2", albumName: "Album Two", rank: 4)
        ]
        sut.calculateTopAlbums()
        let albums = sut.topAlbumsList["short"]
        #expect(albums?[0].rank == 1)
        #expect(albums?[1].rank == 2)
    }

    @Test("calculateTopAlbums produces empty arrays for all three time ranges when no songs")
    func emptyInputProducesEmptyOutputForAllRanges() {
        let sut = UserTopItems()
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.isEmpty == true)
        #expect(sut.topAlbumsList["medium"]?.isEmpty == true)
        #expect(sut.topAlbumsList["long"]?.isEmpty == true)
    }

    @Test("Album IDs encode time range and rank for SwiftUI uniqueness")
    func albumIdEncoding() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Album One", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Album One", rank: 2)
        ]
        sut.calculateTopAlbums()
        let album = sut.topAlbumsList["short"]?.first
        #expect(album?.id == "short-1-alb1")
    }

    @Test("calculateTopAlbums is independent per time range")
    func independentPerTimeRange() {
        let sut = UserTopItems()
        sut.topSongsList["short"] = [
            makeSong(name: "Song 1", spotifyId: "s1", albumId: "alb1", albumName: "Hit Album", rank: 1),
            makeSong(name: "Song 2", spotifyId: "s2", albumId: "alb1", albumName: "Hit Album", rank: 2)
        ]
        sut.calculateTopAlbums()
        #expect(sut.topAlbumsList["short"]?.count == 1)
        #expect(sut.topAlbumsList["medium"]?.isEmpty == true)
        #expect(sut.topAlbumsList["long"]?.isEmpty == true)
    }
}

// MARK: - AuthManager Tests

@MainActor
@Suite("AuthManager")
struct AuthManagerTests {

    @Test("logout() clears tokens and sets isAuthenticated to false")
    func logoutClearsState() {
        let sut = AuthManager()
        sut.accessToken = "some-access-token"
        sut.tokenType = "Bearer"

        sut.logout()

        #expect(sut.accessToken == nil)
        #expect(sut.tokenType == nil)
        #expect(sut.isAuthenticated == false)
    }
}
```

- [ ] **Step 2: Run tests to verify they still pass (before changing `UserTopItems`)**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E 'passed|failed|error:'
```

Expected: all 25 tests pass. If any fail, do not proceed — diagnose and fix first.

- [ ] **Step 3: Replace `UserTopItems.swift` with the full async version**

```swift
//
//  UserTopItems.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import Foundation

@MainActor
class UserTopItems: ObservableObject {
    @Published var topSongsResponse: [String: [SongResponse]]
    @Published var topArtistsResponse: [String: [ArtistResponse]]
    @Published var topSongsList: [String: [Song]]
    @Published var topArtistsList: [String: [Artist]]
    @Published var topAlbumsList: [String: [Album]]
    @Published var userProfile: UserProfile?
    @Published var fetchState: ViewState = .loading
    var accessToken: String
    var tokenType: String

    init() {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.topAlbumsList = [:]
        self.userProfile = nil
        self.accessToken = ""
        self.tokenType = ""
    }

    func getUserProfile() async {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me"

        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }

        if let responseObject = try? JSONDecoder().decode(UserProfileResponse.self, from: data) {
            userProfile = UserProfile(
                id: responseObject.id,
                displayName: responseObject.displayName,
                email: responseObject.email,
                images: responseObject.images
            )
        }
    }

    func getTopSongs() async throws {
        async let short = getSongsForTimeRange(range: "short_term", offset: 0)
        async let medium = getSongsForTimeRange(range: "medium_term", offset: 0)
        async let long = getSongsForTimeRange(range: "long_term", offset: 0)
        let (shortResponse, mediumResponse, longResponse) = try await (short, medium, long)

        for (key, response) in zip(["short", "medium", "long"], [shortResponse, mediumResponse, longResponse]) {
            topSongsResponse[key] = response.items
            topSongsList[key] = response.items.enumerated().map { (index, songResponse) in
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
                let rank = index + 1
                let artists = songResponse.artists.map {
                    Artist(id: "song-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
                }
                return Song(
                    id: "\(key)-\(rank)-\(songResponse.id)",
                    spotifyId: songResponse.id,
                    rank: rank,
                    album: album,
                    artists: artists,
                    durationMs: songResponse.durationMs,
                    name: songResponse.name,
                    popularity: songResponse.popularity
                )
            }
        }
        calculateTopAlbums()
    }

    func getTopArtists() async throws {
        async let short = getArtistsForTimeRange(range: "short_term", offset: 0)
        async let medium = getArtistsForTimeRange(range: "medium_term", offset: 0)
        async let long = getArtistsForTimeRange(range: "long_term", offset: 0)
        let (shortResponse, mediumResponse, longResponse) = try await (short, medium, long)

        for (key, response) in zip(["short", "medium", "long"], [shortResponse, mediumResponse, longResponse]) {
            topArtistsResponse[key] = response.items
            topArtistsList[key] = response.items.enumerated().map { (index, artistResponse) in
                let rank = index + 1
                return Artist(
                    id: "\(key)-\(rank)-\(artistResponse.id)",
                    spotifyId: artistResponse.id,
                    rank: rank,
                    images: artistResponse.images,
                    name: artistResponse.name,
                    popularity: artistResponse.popularity,
                    genres: artistResponse.genres
                )
            }
        }
    }

    func fetchAll() async {
        do {
            async let songs: Void = getTopSongs()
            async let artists: Void = getTopArtists()
            try await songs
            try await artists
            fetchState = .content
        } catch {
            fetchState = .error
        }
    }

    func retry() {
        fetchState = .loading
        topSongsResponse = [:]
        topArtistsResponse = [:]
        topSongsList = [:]
        topArtistsList = [:]
        topAlbumsList = [:]
        Task {
            await getUserProfile()
            await fetchAll()
        }
    }

    func calculateTopAlbums() {
        let keys = ["short", "medium", "long"]
        for key in keys {
            guard let songs = topSongsList[key] else {
                self.topAlbumsList[key] = []
                continue
            }

            var albumToSongs: [String: [Song]] = [:]
            for song in songs {
                albumToSongs[song.album.id, default: []].append(song)
            }

            let filteredAlbums = albumToSongs.filter { $1.count > 1 }

            let sortedAlbumIds = filteredAlbums.keys.sorted { id1, id2 in
                let songs1 = filteredAlbums[id1]!
                let songs2 = filteredAlbums[id2]!

                if songs1.count != songs2.count {
                    return songs1.count > songs2.count
                }

                let bestRank1 = songs1.compactMap { $0.rank }.min() ?? Int.max
                let bestRank2 = songs2.compactMap { $0.rank }.min() ?? Int.max

                return bestRank1 < bestRank2
            }

            self.topAlbumsList[key] = sortedAlbumIds.enumerated().map { index, albumId in
                let songs = filteredAlbums[albumId]!
                let firstSong = songs[0]
                return Album(
                    id: "\(key)-\(index + 1)-\(albumId)",
                    spotifyId: albumId,
                    rank: index + 1,
                    images: firstSong.album.images,
                    name: firstSong.album.name,
                    artists: firstSong.artists,
                    releaseDate: firstSong.album.releaseDate
                )
            }
        }
    }

    func getSongsForTimeRange(range: String, offset: Int) async throws -> TopSongsResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/tracks"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(TopSongsResponse.self, from: data)
    }

    func getArtistsForTimeRange(range: String, offset: Int) async throws -> TopArtistsResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/artists"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(TopArtistsResponse.self, from: data)
    }

    func reset() {
        topSongsResponse = [:]
        topArtistsResponse = [:]
        topSongsList = [:]
        topArtistsList = [:]
        topAlbumsList = [:]
        userProfile = nil
        accessToken = ""
        tokenType = ""
        fetchState = .loading
    }
}

// MARK: - Individual Item Fetching
extension UserTopItems {
    func getTrack(id: String) async throws -> SongResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/tracks/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(SongResponse.self, from: data)
    }

    func getArtist(id: String) async throws -> ArtistResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/artists/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(ArtistResponse.self, from: data)
    }

    func getAlbum(id: String) async throws -> AlbumResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/albums/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(AlbumResponse.self, from: data)
    }
}
```

- [ ] **Step 4: Run tests to verify all 25 still pass**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E 'passed|failed|error:'
```

Expected: all 25 tests pass. If any fail, do not proceed.

- [ ] **Step 5: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/UserTopItems.swift" \
        "Music Stats iOS/Music Stats iOSTests/MusicStatsiOSTests.swift"
git commit -m "refactor: convert UserTopItems to @MainActor + async/await"
```

---

## Task 4: Update `TabUIView` to use `.task` modifier

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift`

**Background:** `TabUIView.onAppear` currently calls `userTopItems.fetchAll()` and `userTopItems.getUserProfile {}`. The `.task` modifier replaces `.onAppear` for async work — it is automatically cancelled if the view disappears. `getUserProfile` and `fetchAll` are launched concurrently via `async let`.

- [ ] **Step 1: Replace `TabUIView.swift`**

```swift
//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI
import Foundation

struct TabUIView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var userTopItems = UserTopItems()

    var body: some View {
        TabView {
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                TopSongsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Top Songs")
                    }
                TopAlbumsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "square.stack")
                        Text("Top Albums")
                    }
                TopArtistsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.mic")
                        Text("Top Artists")
                    }
            } else {
                ProgressView()
            }
        }
        .environmentObject(userTopItems)
        .task {
            if let accessToken = authManager.accessToken,
               let tokenType = authManager.tokenType {
                userTopItems.accessToken = accessToken
                userTopItems.tokenType = tokenType
                async let profile: Void = userTopItems.getUserProfile()
                async let data: Void = userTopItems.fetchAll()
                await profile
                await data
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift"
git commit -m "refactor: TabUIView uses .task modifier for async fetch"
```

---

## Task 5: Update detail views to use `.task` modifier

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift`

**Background:** Each detail view currently calls a private `fetchXDetails()` method from `.onAppear`. That method calls a `userTopItems.getX(id:) { response in ... }` completion handler. With async/await, the private fetch method is removed entirely and replaced by an inline `.task { do { x = try await userTopItems.getX(id:) } catch {} }` block. The `isLoading` flag is set to `false` after the await (whether it succeeded or failed), preserving the existing "Failed to load" text on error.

- [ ] **Step 1: Replace `SongDetailView.swift`**

```swift
// SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var song: SongResponse?
    @State private var isLoading = true

    private func artistsToString(artists: [ArtistResponse]) -> String {
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private func formatDuration(ms duration: Int) -> String {
        let totalSeconds = duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Track Details...")
                    .padding(.top, 50)
            } else if let song = song {
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

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load track details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                song = try await userTopItems.getTrack(id: spotifyId)
            } catch {
                // song remains nil; view shows "Failed to load track details."
            }
            isLoading = false
        }
    }
}

struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SongDetailView(spotifyId: "testId", rank: 1)
            .environmentObject(UserTopItems())
    }
}
```

- [ ] **Step 2: Replace `ArtistDetailView.swift`**

```swift
// ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var artist: ArtistResponse?
    @State private var isLoading = true

    private func genresToString(genres: [String]?) -> String {
        return genres?.joined(separator: ", ") ?? "N/A"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Artist Details...")
                    .padding(.top, 50)
            } else if let artist = artist {
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

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load artist details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                artist = try await userTopItems.getArtist(id: spotifyId)
            } catch {
                // artist remains nil; view shows "Failed to load artist details."
            }
            isLoading = false
        }
    }
}

struct ArtistDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistDetailView(spotifyId: "testId", rank: 1)
            .environmentObject(UserTopItems())
    }
}
```

- [ ] **Step 3: Replace `AlbumDetailView.swift`**

```swift
// AlbumDetailView.swift

import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var album: AlbumResponse?
    @State private var isLoading = true

    private func artistsToString(artists: [ArtistResponse]?) -> String {
        return artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown Artist"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Album Details...")
                    .padding(.top, 50)
            } else if let album = album {
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
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load album details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                album = try await userTopItems.getAlbum(id: spotifyId)
            } catch {
                // album remains nil; view shows "Failed to load album details."
            }
            isLoading = false
        }
    }
}
```

- [ ] **Step 4: Run the full test suite**

```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E 'passed|failed|error:'
```

Expected: all 25 tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongDetailView.swift" \
        "Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistDetailView.swift" \
        "Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumDetailView.swift"
git commit -m "refactor: detail views use .task modifier for async fetch"
```
