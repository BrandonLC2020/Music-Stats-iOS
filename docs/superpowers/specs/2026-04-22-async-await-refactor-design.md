# Async/Await Networking Refactor — Design Spec

**ClickUp:** 86b9gcvu1
**Date:** 2026-04-22
**Status:** Approved

---

## Goal

Replace all completion-handler-based networking with modern Swift concurrency (async/await) across `UserTopItems`, `AuthManager`, and the views that call them. Eliminate all `DispatchGroup` and `DispatchQueue.main.async` usage.

## Context

All networking in `UserTopItems.swift` and `AuthManager.swift` uses `URLSession.dataTask` with `@escaping` completion closures. Fan-out over three time ranges is coordinated with `DispatchGroup`. UI updates are dispatched back to the main thread manually with `DispatchQueue.main.async`. This pattern is verbose, error-prone (easy to miss a `group.leave()` or a `DispatchQueue.main.async`), and harder to reason about than structured concurrency.

---

## Architecture

### Core pattern: `@MainActor` on both observable classes

`UserTopItems` and `AuthManager` are both annotated `@MainActor`. This means:

- Every `@Published` property write is automatically on the main thread — the compiler enforces it.
- All `DispatchQueue.main.async {}` calls are removed.
- Network I/O is performed by `URLSession.data(for:)` (the built-in async variant), which suspends the caller without blocking the main thread.
- Methods can interleave at suspension points (`await`), so concurrent fetches still run concurrently at the I/O layer even though the class is main-actor-isolated.

### Error boundary

Low-level fetch methods (`getSongsForTimeRange`, `getArtistsForTimeRange`, `getTrack`, `getArtist`, `getAlbum`) are `async throws`. HTTP errors throw `NetworkError.badStatusCode(Int)`; network and decoding errors propagate as `URLError` and `DecodingError` respectively.

`fetchAll()` is the catch boundary for bulk fetching — it catches all errors and sets `fetchState = .error`. Detail-view fetches catch at their `.task` boundary and leave the item `nil`, triggering the existing "Failed to load" text.

No errors are silently swallowed or printed to console.

---

## Files to Create

| File | Purpose |
|------|---------|
| `Types/NetworkError.swift` | One-case error enum: `badStatusCode(Int)` |

## Files to Modify

| File | Changes |
|------|---------|
| `UserTopItems.swift` | Add `@MainActor`; convert all methods to `async throws`; replace `DispatchGroup` with `async let`; remove `DispatchQueue.main.async` |
| `AuthManager.swift` | Add `@MainActor`; convert token methods to `async`; replace `handleTokenResponse` with shared `performTokenRequest`; update `init()` and `logIn(with:)` |
| `Tabs/TabUIView.swift` | Replace `.onAppear` with `.task`; run `getUserProfile` and `fetchAll` concurrently via `async let` |
| `Tabs/Top Songs/SongDetailView.swift` | Replace `onAppear` + completion-handler method with `.task` + `try await` |
| `Tabs/Top Artists/ArtistDetailView.swift` | Same pattern as SongDetailView |
| `Tabs/Top Albums/AlbumDetailView.swift` | Same pattern as SongDetailView |
| `Music Stats iOSTests/MusicStatsiOSTests.swift` | Add `@MainActor` to `UserTopItemsTests` suite so tests run on the main actor (required for `@MainActor`-isolated class) |

---

## Detailed Component Changes

### `Types/NetworkError.swift`

```swift
enum NetworkError: Error {
    case badStatusCode(Int)
}
```

### `UserTopItems`

**Class declaration:**
```swift
@MainActor class UserTopItems: ObservableObject { ... }
```

**Primitive fetchers** — return value directly instead of passing to completion:
```swift
func getSongsForTimeRange(range: String, offset: Int) async throws -> TopSongsResponse
func getArtistsForTimeRange(range: String, offset: Int) async throws -> TopArtistsResponse
func getTrack(id: String) async throws -> SongResponse
func getArtist(id: String) async throws -> ArtistResponse
func getAlbum(id: String) async throws -> AlbumResponse
func getUserProfile() async  // non-throwing; failures silently skip the update
```

**Fan-out with `async let`** — replaces `DispatchGroup` inside `getTopSongs` and `getTopArtists`:
```swift
func getTopSongs() async throws {
    async let short = getSongsForTimeRange(range: "short_term", offset: 0)
    async let medium = getSongsForTimeRange(range: "medium_term", offset: 0)
    async let long = getSongsForTimeRange(range: "long_term", offset: 0)
    let (shortResponse, mediumResponse, longResponse) = try await (short, medium, long)
    // map responses to display types and assign to @Published properties
}
```

**`fetchAll()`** — `async`, non-throwing; uses `async let` so songs and artists fetch concurrently:
```swift
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
```

**`retry()`** — stays a regular (non-async) function; creates a `Task` internally so SwiftUI `Button` actions don't need `Task {}` wrappers at the call site:
```swift
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
```

**`reset()`** — `DispatchQueue.main.async` wrapper removed; direct property assignment is safe because the class is `@MainActor`.

**`calculateTopAlbums()`** — pure computation; unchanged.

### `AuthManager`

**Class declaration:**
```swift
@MainActor class AuthManager: ObservableObject { ... }
```

**Shared token handler** — replaces `handleTokenResponse`:
```swift
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
```

**`refreshToken()`** and **`exchangeCodeForTokens(code:)`** both become `async` and call `await performTokenRequest(request)`.

**`init()`** — uses `Task {}` to call the now-async `refreshToken()`:
```swift
init() {
    if keychain.get("refreshToken") != nil {
        Task { await refreshToken() }
    } else {
        isLoading = false
    }
}
```

**`logIn(with:)`** — wraps async call in `Task`:
```swift
func logIn(with code: String) {
    isLoading = true
    Task { await exchangeCodeForTokens(code: code) }
}
```

**`logout()`** — `DispatchQueue.main.async` wrapper removed.

### Views

**`TabUIView`** — replaces `.onAppear` with `.task`; `getUserProfile` and `fetchAll` run concurrently:
```swift
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
```

**`SongDetailView` / `ArtistDetailView` / `AlbumDetailView`** — replace `onAppear { fetchXDetails() }` with `.task`:
```swift
.task {
    do {
        song = try await userTopItems.getTrack(id: spotifyId)
    } catch {
        // song remains nil; view shows "Failed to load" text
    }
    isLoading = false
}
```

---

## Testing

The existing `UserTopItemsTests` suite tests synchronous state transitions (`fetchState` initial value, `reset()`, `retry()`). With `@MainActor` on `UserTopItems`, the test suite must also run on the main actor.

**Change:** Add `@MainActor` to the `UserTopItemsTests` struct declaration. No new tests needed — the async networking methods are not unit-testable without URLSession mocking, which is out of scope.

---

## Success Criteria

- App compiles without concurrency warnings
- No `DispatchGroup`, `DispatchQueue.main.async`, or `@escaping` completion handlers remain in networking code
- Data fetching works correctly across all three time ranges
- Network errors surface as `fetchState = .error` (retryable via existing UI)
- Detail view failures show "Failed to load" text (existing behavior preserved)
- All 25 existing unit tests pass
