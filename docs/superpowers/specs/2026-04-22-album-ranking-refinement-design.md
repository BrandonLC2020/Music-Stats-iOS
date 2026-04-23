# Album Ranking Refinement — Design Spec

**Task:** 86b9gcvu2  
**Date:** 2026-04-22  
**Status:** Approved

---

## Goal

Improve the accuracy and depth of the locally calculated "Top Albums" list by:
1. Merging deluxe/edition variants under a single album entry
2. Weighting album rank by individual song ranks (not just song count)
3. Surfacing `totalTracks` and `songCount` metadata in the display model

---

## Context

Spotify has no "Top Albums" endpoint. The app derives top albums in `UserTopItems.calculateTopAlbums()` by grouping the user's top 50 songs by `song.album.id`. The current ranking sorts by `(songCount DESC, bestRank ASC)`. Two problems:

1. **Deluxe editions split votes** — "Midnights" and "Midnights (3am Edition)" have different Spotify IDs, so songs from both editions count separately rather than combining.
2. **Song count dominates** — an album with two #49-ranked songs outranks one with only the #1 song.

---

## Design

### 1. Album Name Normalization

A private helper `normalizeAlbumName(_ name: String) -> String` is added to `UserTopItems`.

**Behavior:**
- Strips common edition suffixes using a regex that matches parenthetical/bracketed tokens: `(Deluxe Edition)`, `(3am Edition)`, `[Remastered]`, `(Special Edition)`, `(Bonus Tracks)`, `(Anniversary Edition)`, `(Super Deluxe)`, `(Expanded Edition)`, `(Platinum Edition)`, `(Collector's Edition)`, `(Remaster)`, `(Reissue)`, `(Deluxe Version)`, `(Bonus Track Version)`.
- Lowercases and trims whitespace.

**Grouping key:** Changes from `song.album.id` to `"\(normalizedName)||\(primaryArtistId)"`, where `primaryArtistId` is the Spotify ID of the first artist in `song.album.artists` (falls back to `"unknown"` if missing).

**Representative album:** When multiple editions are merged into one group, the album with the **shortest name** is used as the display representative (cleanest base edition). All songs from every edition in the group are pooled.

---

### 2. Weighted Score Ranking

The sort in `calculateTopAlbums()` is replaced with a weighted score:

```
score = songs.reduce(0) { $0 + (51 - ($1.rank ?? 51)) }
```

- Song ranked #1 → 50 pts, #25 → 26 pts, #50 → 1 pt
- Albums are sorted by `score DESC`
- Song count is implicitly rewarded (more songs always add more points)
- A single high-ranked song can outrank multiple low-ranked songs from another album
- No secondary sort needed; score encodes both depth and quality

---

### 3. Display Model Updates

**`Album` struct** (`Types/IdentifiableTypes.swift`) gains two new optional fields:

| Field | Type | Source | Purpose |
|---|---|---|---|
| `totalTracks` | `Int?` | `SongResponse.album.totalTracks` — already in every track response, no extra API calls | Available for list/detail display |
| `songCount` | `Int?` | Computed in `calculateTopAlbums()` as the count of pooled songs | Shown in `AlbumDetailView` |

**`AlbumDetailView`** gains a `songCount: Int?` parameter and displays a **"Songs in Your Top 50"** row (e.g. `"3"`) alongside the existing Release Date, Total Tracks, Label, Popularity, and Rank rows. This directly communicates to the user why an album ranked where it did.

**`AlbumCard`** is unchanged — no list-level metadata display change is needed.

**`TopAlbumsView`** passes `album.songCount` to `AlbumDetailView` in the `navigationDestination` closure.

---

## Files Changed

| File | Change |
|---|---|
| `Types/IdentifiableTypes.swift` | Add `totalTracks: Int?` and `songCount: Int?` to `Album` |
| `UserTopItems.swift` | Add `normalizeAlbumName()`, refactor `calculateTopAlbums()` grouping key and sort |
| `UserTopItems.swift` | Populate `totalTracks` and `songCount` when building `Album` in `calculateTopAlbums()` |
| `UserTopItems.swift` | Populate `totalTracks` on `Album` objects built in `getTopSongs()` |
| `Tabs/Top Albums/AlbumDetailView.swift` | Add `songCount: Int?` parameter, add "Songs in Your Top 50" detail row |
| `Tabs/Top Albums/TopAlbumsView.swift` | Pass `album.songCount` to `AlbumDetailView` |

---

## Out of Scope

- Eager fetching of `label` or `popularity` for the album list view — `AlbumDetailView` already fetches these on-demand via `getAlbum(id:)`.
- Any UI change to `AlbumCard`.
- Changes to `TopSongsView`, `TopArtistsView`, or `ArtistDetailView`.

---

## Success Criteria

- An album with the #1 song ranks above an album with two #49-ranked songs.
- "Midnights" and "Midnights (3am Edition)" merge into a single entry.
- `AlbumDetailView` displays a "Songs in Your Top 50" row with the correct count.
- No additional Spotify API calls are made during album ranking calculation.
