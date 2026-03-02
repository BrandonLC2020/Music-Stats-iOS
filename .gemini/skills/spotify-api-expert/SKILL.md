---
name: spotify-api-expert
description: Expertise in the Spotify Web API, including OAuth2, scopes, pagination, and data modeling for top items and albums. Use when adding features related to Spotify data or modifying API calls.
---

# Spotify API Expert

This skill provides specialized knowledge for working with the Spotify Web API within the Music-Stats-iOS project.

## Core Scopes
Ensure any new feature uses the correct OAuth2 scopes:
- `user-top-read`: Required for `/me/top/tracks` and `/me/top/artists`.
- `user-read-private`: Required for basic user profile information.

## API Patterns
### Top Items Pagination
When fetching top tracks or artists, use the `limit` and `offset` parameters. The maximum limit is 50.
Example: `https://api.spotify.com/v1/me/top/tracks?time_range=long_term&limit=50`

### Album Calculation Logic
Spotify does not have a "Top Albums" endpoint. This project calculates top albums by:
1. Fetching the top 50 tracks.
2. Grouping tracks by their `album.id`.
3. Counting occurrences to rank albums.
4. Fetching full album details if necessary.

## Best Practices
- **Rate Limiting**: Spotify uses the `Retry-After` header. If a 429 occurs, wait for the specified duration.
- **Snake Case**: API responses use `snake_case`. Ensure `JSONDecoder` is configured with `.convertFromSnakeCase`.
- **Image Selection**: Use the largest available image for detail views and the smallest for cards to optimize performance.
