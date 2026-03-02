---
name: swift-ui-clean-architecture
description: Expertise in SwiftUI architectural patterns, state management with @StateObject and @Published, and building modern, responsive UIs. Use when adding new tabs, views, or refactoring existing UI.
---

# SwiftUI Clean Architecture

This skill ensures consistent and high-quality UI development for the Music-Stats-iOS app.

## State Management
The project uses standard SwiftUI observable objects:
- **`AuthManager`**: Singleton for handling Spotify authentication. Access via `@StateObject` in the app entry point.
- **`UserTopItems`**: Manages the data layer for top items. It fetches data and holds the published arrays for songs, artists, and albums.

## UI Patterns
### Component Organization
- **Tabs**: Main entry views for navigation (e.g., `TopSongsView`).
- **Cards**: Reusable components for the lists (e.g., `SongCard`).
- **Details**: Full-screen views for detailed data (e.g., `SongDetailView`).

### Aesthetics
- Use **Glassmorphism** where possible.
- Use `AsyncImage` with proper error handling and placeholder views.
- Ensure all views support both Light and Dark modes.

## Coding Standards
- Prefer `computed properties` for simple UI logic.
- Use `Extensions` to separate UI formatting from data logic.
- Ensure all views are `Identifiable` or use `id: \.self` correctly in `ForEach`.
- Always provide meaningful accessibility labels for interactive elements.
