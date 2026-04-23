# Spotify Deep Linking — Design Spec

**Task:** 86b9gcvu0
**Date:** 2026-04-23
**Status:** Approved

---

## Goal

Enable users to jump from a detail view directly to the correct item in the Spotify app (or Spotify web if the app is not installed).

---

## Context

`SongDetailView`, `ArtistDetailView`, and `AlbumDetailView` currently display read-only metadata. Adding a direct "Open in Spotify" button increases the app's utility without requiring any additional API calls or model changes.

---

## Design

### URL Construction

Each detail view already receives `spotifyId: String`. The Spotify web URL is constructed at the call site using the known-stable path patterns:

| View | URL |
|---|---|
| `SongDetailView` | `https://open.spotify.com/track/{spotifyId}` |
| `ArtistDetailView` | `https://open.spotify.com/artist/{spotifyId}` |
| `AlbumDetailView` | `https://open.spotify.com/album/{spotifyId}` |

`open.spotify.com` is registered as a universal link by the Spotify iOS app. iOS automatically routes universal links to the registered app when installed, and falls back to Safari when not. No explicit fallback code is required.

No changes are needed to `CodableTypes.swift`, `IdentifiableTypes.swift`, or `UserTopItems.swift`.

### Navigation

The button calls `UIApplication.shared.open(url)` where `url` is the constructed universal link. This is called from the button's action closure on the main thread (SwiftUI button actions are always on the main actor).

### Button Appearance

A full-width `Button` placed below the metadata `VStack` and above the existing `Spacer` in each detail view.

- **Style:** `.buttonStyle(.borderedProminent)`
- **Tint:** `Color(red: 0.114, green: 0.725, blue: 0.329)` (Spotify green `#1DB954`)
- **Label:** `"Open in Spotify"`
- **Width:** `.frame(maxWidth: .infinity)` for full-width layout

The button only renders inside the `if let song/artist/album = ...` branch, consistent with how existing metadata rows are guarded.

---

## Files Changed

| File | Change |
|---|---|
| `Tabs/Top Songs/SongDetailView.swift` | Add "Open in Spotify" button below metadata rows |
| `Tabs/Top Artists/ArtistDetailView.swift` | Add "Open in Spotify" button below metadata rows |
| `Tabs/Top Albums/AlbumDetailView.swift` | Add "Open in Spotify" button below metadata rows |

---

## Out of Scope

- Changes to `CodableTypes.swift` — no new fields needed.
- Changes to `IdentifiableTypes.swift` or `UserTopItems.swift`.
- Changes to list views (`TopSongsView`, `TopArtistsView`, `TopAlbumsView`).
- Custom button icon or Spotify logo asset.

---

## Success Criteria

- Tapping "Open in Spotify" on a song/artist/album opens the correct item in the Spotify app.
- When Spotify is not installed, the button opens the correct Spotify web page in Safari.
- The button is only visible when detail data has loaded successfully.
- No additional Spotify API calls are made.
