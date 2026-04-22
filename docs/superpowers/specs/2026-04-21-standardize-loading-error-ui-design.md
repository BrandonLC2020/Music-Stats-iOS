# Standardize Loading & Error UI States — Design Spec

**ClickUp:** 86b9gcvtz  
**Date:** 2026-04-21  
**Status:** Approved

---

## Goal

Create a set of reusable SwiftUI components to handle loading, error, and empty data states consistently across all three main tabs (Top Songs, Top Artists, Top Albums).

## Context

Current tab views use inconsistent, duplicated patterns:
- `TopSongsView` and `TopArtistsView`: nil-based loading only — no error state, no empty state
- `TopAlbumsView`: adds an empty state but still no error state
- `UserTopItems`: errors are silently dropped (nil returned from completions), no `@Published` error state exists — the UI cannot distinguish "still loading" from "fetch failed"

---

## Architecture

### 1. State Model

**New file:** `Types/ViewState.swift`

```swift
enum ViewState {
    case loading
    case content
    case error
    case empty
}
```

**Changes to `UserTopItems`:**

- Add `@Published var fetchState: ViewState = .loading`
- `getTopSongs` + `getTopArtists` run together (fan-out via `DispatchGroup`); on completion:
  - If any fetch returns `nil` → set `fetchState = .error`
  - If all succeed → set `fetchState = .content`
- `reset()` resets `fetchState = .loading` along with data dictionaries
- New `retry()` method: calls `reset()` then re-runs `getUserProfile {}`, `getTopSongs {}`, `getTopArtists {}` — mirroring what `TabUIView.onAppear` does

**Error scope:** Global. All three fetches fire together at startup; a failure in any one means all tabs are broken (Albums is derived from Songs, so a songs failure cascades). One shared `fetchState` + one retry path is simpler and more honest than per-tab tracking.

### 2. `StateContainerView` Component

**New file:** `StateContainerView.swift`

A generic SwiftUI view that takes:
- `state: ViewState` — the current state
- `loadingLabel: String` — e.g. `"Loading Songs…"`
- `emptySymbol: String` — SF Symbol name for empty state
- `emptyTitle: String` — bold title for empty state
- `emptyDescription: String` — secondary description for empty state
- `onRetry: () -> Void` — called when the user taps "Tap to Retry"
- `@ViewBuilder content: () -> Content` — the actual list content shown in `.content` state

**Rendering per state:**
- `.loading` → `ProgressView(loadingLabel)`
- `.content` → `content()`
- `.error` → SF Symbol (`exclamationmark.triangle`) + "Something went wrong" title + "Tap to Retry" button
- `.empty` → SF Symbol + `emptyTitle` + `emptyDescription` (matches existing `TopAlbumsView` empty state visual style)

### 3. Tab View Changes

Each tab view becomes a thin shell. Pattern:

```swift
NavigationStack {
    StateContainerView(
        state: resolvedState,   // see below
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note.list",
        emptyTitle: "No Top Albums Found",
        emptyDescription: "...",
        onRetry: { userTopItems.retry() }
    ) {
        ScrollView { LazyVStack { ... } }  // existing content, unchanged
    }
    .navigationTitle("Top Songs")
    .toolbar { ... }
}
```

**State resolution:**
- `TopSongsView` and `TopArtistsView`: pass `userTopItems.fetchState` directly (neither can reach `.empty`)
- `TopAlbumsView`: if `fetchState == .content && albums.isEmpty` → pass `.empty`; otherwise pass `fetchState`

**Toolbar behavior:** The calendar picker and profile button remain attached to the `NavigationStack` outside `StateContainerView` — visible in all states.

---

## Files to Create

| File | Purpose |
|------|---------|
| `Types/ViewState.swift` | `ViewState` enum |
| `StateContainerView.swift` | Generic state-switching container view |

## Files to Modify

| File | Changes |
|------|---------|
| `UserTopItems.swift` | Add `fetchState`, set it in fetch completions, add `retry()`, update `reset()` |
| `Tabs/Top Songs/TopSongsView.swift` | Wrap content in `StateContainerView` |
| `Tabs/Top Artists/TopArtistsView.swift` | Wrap content in `StateContainerView` |
| `Tabs/Top Albums/TopAlbumsView.swift` | Wrap content in `StateContainerView`, resolve `.empty` state |

---

## Testing

Unit tests on `UserTopItems` for state transitions:
- `fetchState` starts as `.loading`
- `fetchState` becomes `.content` after both fetches complete with valid data
- `fetchState` becomes `.error` when any fetch fails (nil from completion)
- `retry()` resets `fetchState` to `.loading` and clears data dictionaries

`StateContainerView` gets SwiftUI Previews (one per state) rather than unit tests — previews are the appropriate regression check for a pure UI component.

---

## Success Criteria

- All three main tabs use `StateContainerView` for loading/error/empty rendering
- No duplicated loading or error logic in tab views
- Network failures surface an error state with a working "Tap to Retry" button
- Empty state for Top Albums is visually consistent (matches existing style)
- Toolbar always visible regardless of state
