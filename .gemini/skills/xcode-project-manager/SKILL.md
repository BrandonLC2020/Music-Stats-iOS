---
name: xcode-project-manager
description: Expertise in managing Xcode project structures, Build Settings via .xcconfig files, and target management. Use when adding new files, modifying build settings, or fixing project file issues.
---

# Xcode Project Manager

This skill provides specialized knowledge for managing the Xcode project and its configuration for the Music-Stats-iOS app.

## Project Structure
- Source code: `Music Stats iOS/Music Stats iOS/`
- Resources: `Music Stats iOS/Music Stats iOS/Assets.xcassets/`
- Tests: `Music Stats iOS/Music Stats iOSTests/`

## Configuration
### Using `.xcconfig`
The project uses `Config.xcconfig` for sensitive API credentials.
Keys to manage:
- `SPOTIFY_API_CLIENT_ID`: OAuth client ID.
- `SPOTIFY_API_CLIENT_SECRET`: OAuth client secret.
- `REDIRECT_URI_SCHEME`: App URL scheme (e.g., `musicstats`).
- `REDIRECT_URI_HOST`: Redirect host (e.g., `callback`).

### Managing the `.xcodeproj`
- Avoid manual edits to `project.pbxproj` when possible; use `XcodeWrite`, `XcodeUpdate`, or `XcodeMV` tools to let the MCP server handle it.
- Ensure new files are added to the correct group and target.

## Build and Test
- **Build**: Use `xcodebuild build` with the proper scheme and destination.
- **Test**: Ensure tests are run after any architectural changes.
- **Schemes**: Always use the `Music Stats iOS` scheme for production builds.
