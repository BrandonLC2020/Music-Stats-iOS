# Design Spec: Settings Tab and Global Blur Control

**Date:** 2026-04-25
**Status:** Pending Review

## Overview
Implement a fourth tab in the `TabUIView` for application settings. This tab will allow users to manage their Spotify account session and customize the visual intensity of the glassmorphism blur effect used across the app's card components.

## Goals
- Provide a clear "Logout" path for the authenticated Spotify account.
- Centralize visual preferences using a global setting.
- Ensure UI consistency across all "Top Item" views.

## User Interface
### Settings Tab
- **Tab Icon:** `gearshape` (SF Symbol).
- **Sections:**
    1. **Account**: 
        - Display current user's profile picture and name.
        - "Log Out" button (destructive style).
    2. **Appearance**:
        - "Card Blur Intensity" picker.
        - Options: None, Subtle, Default, Strong.

### Visual Impact
- Selecting a different blur intensity will immediately update all `SongCard`, `AlbumCard`, and `ArtistCard` components in the other tabs.

## Technical Architecture

### 1. Data Models
Create a `BlurIntensity` enum to manage the discrete levels.

```swift
enum BlurIntensity: Int, CaseIterable, Identifiable {
    case none = 0
    case subtle = 3
    case standard = 5
    case strong = 10
    
    var id: Int { self.rawValue }
    var displayName: String { ... }
}
```

### 2. State Management & Persistence
- **Storage:** Use `@AppStorage("cardBlurIntensity")` in `MusicStatsiOSApp.swift` to persist the selected intensity level as an `Int`.
- **Environment:** Create a custom `EnvironmentKey` called `CardBlurKey` to propagate the current blur radius (CGFloat) down the view hierarchy.

### 3. Component Updates
- **Cards:** Modify `SongCard`, `AlbumCard`, and `ArtistCard` to read the blur radius from `@Environment(\.cardBlur)`.
- **SettingsView:** New SwiftUI view for the settings interface.
- **TabUIView:** Add the fourth `SettingsView` tab.

## Data Flow
1. User changes the picker in `SettingsView`.
2. `@AppStorage` updates the value in `MusicStatsiOSApp`.
3. `MusicStatsiOSApp` passes the new value into the `.environment` modifier.
4. All active Card views reactively rebuild with the new blur radius.

## Testing Strategy
- **Unit Test**: Verify that `BlurIntensity` correctly maps enum cases to their respective `rawValue` radii.
- **UI Test**: Navigate to Settings, change blur intensity, and verify that the app doesn't crash and returns to other tabs correctly.
- **Manual Verification**: Confirm that Logout clears the session and redirects to `AuthorizationView`.
