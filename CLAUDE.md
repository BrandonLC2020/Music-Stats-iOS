# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development

This is a pure Xcode project — there is no Makefile, Fastfile, or package manager CLI.

**Open project:**
```bash
open "Music Stats iOS/Music Stats iOS.xcodeproj"
```

**Build from CLI:**
```bash
xcodebuild build \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Run tests:**
```bash
xcodebuild test \
  -project "Music Stats iOS/Music Stats iOS.xcodeproj" \
  -scheme "Music Stats iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Lint (SwiftLint, if installed):**
```bash
swiftlint lint --path "Music Stats iOS/Music Stats iOS"
```

## Configuration Setup

The app requires a `Config.xcconfig` file (gitignored) before it will build. Copy `Sample.xcconfig` and fill in credentials:

```
SPOTIFY_API_CLIENT_ID = your_client_id
SPOTIFY_API_CLIENT_SECRET = your_client_secret
REDIRECT_URI_SCHEME = your_scheme
REDIRECT_URI_HOST = your_host
```

The redirect URI registered in the Spotify Developer Dashboard must match `your_scheme://your_host`.

## Architecture

**Two observable objects drive the entire app:**

- `AuthManager` — Handles OAuth2 authorization code flow with Spotify. Uses a `WKWebView` (in `AuthorizationView`) to run the web login, intercepts the redirect URI, exchanges the auth code for tokens, and persists the refresh token in the keychain via KeychainSwift. Re-hydrates session on launch by attempting a token refresh from the saved refresh token.

- `UserTopItems` — All data fetching and transformation. Calls the Spotify Web API (`/v1/me/top/tracks`, `/v1/me/top/artists`, individual detail endpoints) using `URLSession` with completion handlers and `DispatchGroup` for fan-out. Exposes `@Published` dictionaries keyed by time range (`"short"`, `"medium"`, `"long"`).

**Data model layers:**
- `Types/CodableTypes.swift` — `Codable` structs matching Spotify API JSON (snake_case mapped via `CodingKeys`).
- `Types/IdentifiableTypes.swift` — Display-layer structs (`Song`, `Artist`, `Album`) that are `Identifiable` and carry rank metadata for use in SwiftUI lists.

**Top Albums derivation** (no Spotify endpoint exists for this): After fetching top 50 songs, `UserTopItems` groups them by album ID, filters to albums with ≥2 songs, then sorts by (1) song count descending, (2) best song rank ascending.

**Navigation:** `TabUIView` is the root; each tab uses a `NavigationStack` with `navigationDestination(item:)` to push detail views. `ProfileToolbarItem` provides the logout action.

**Async pattern:** The codebase uses `URLSession` completion handlers + `DispatchGroup`, not `async/await` or Combine. UI updates are dispatched to `DispatchQueue.main.async`.

## Key Files

| File | Role |
|------|------|
| `MusicStatsiOSApp.swift` | App entry; creates `AuthManager`, routes to auth or main tab view |
| `AuthManager.swift` | OAuth2 flow, token refresh, keychain I/O |
| `UserTopItems.swift` | All API calls, decoding, album ranking logic |
| `AuthorizationView.swift` | WKWebView-based Spotify login + redirect interception |
| `TabUIView.swift` | Root navigation; owns `UserTopItems`, triggers initial fetch |
| `Types/CodableTypes.swift` | Spotify API response models |
| `Types/IdentifiableTypes.swift` | UI-facing display models |
| `Sample.xcconfig` | Template for required API credentials |
