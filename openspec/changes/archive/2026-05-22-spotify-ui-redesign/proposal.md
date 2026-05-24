## Why

The current Sonic Vault app uses a custom editorial/bright design that feels disconnected from modern music app conventions. Users expect a Spotify-like dark UI with familiar patterns — dark backgrounds (#121212), green accent colors (#1DB954), a persistent mini-player bar, 5-tab bottom navigation (Home, Search, Your Library, Premium, Create), album-art-rich cards, and a full-screen now-playing view with large artwork and fluid controls. Redesigning to match the Spotify visual language will make the app feel instantly familiar, premium, and polished.

## What Changes

- **Complete visual overhaul**: Adopt Spotify's dark color system (#121212 background, #1DB954 green accent, #282828 elevated surfaces, #B3B3B3 secondary text)
- **Home screen redesign**: Replace current "Discovery" layout with Spotify-style home — user avatar + filter chips (All / Music / Podcasts), 2-column quick-access shortcut grid, "Jump back in" horizontal carousels with large album art cards
- **Search screen redesign**: New search page with Spotify-style rounded search bar, "Start browsing" section header, 2-column colorful browse category cards (Music, Podcasts, Live Events, Home of I-Pop, etc.)
- **Library screen redesign**: Spotify-style "Your Library" with filter chip row (Playlists, Podcasts, Albums, Artists), sort controls (Recents ↕), grid/list toggle, and vertical list of playlists/albums with square art thumbnails
- **Now Playing redesign**: Full-screen player with context header ("PLAYING FROM SEARCH"), large album artwork, track info with add button, seek slider with time stamps, Spotify-style transport controls (shuffle, prev, play/pause, next, timer), and bottom action bar (lyrics, share, queue icons)
- **Mini Player redesign**: Spotify-style mini-player bar above bottom nav with album art, track info, playback controls (lyrics, add, play icons), and progress indicator
- **Bottom Navigation overhaul**: 5-tab navigation — Home, Search, Your Library, Premium, Create — with Spotify-style icons and active state highlighting
- **Typography update**: Use Spotify's Circular/Gotham-inspired font stack (system fonts or Google Fonts equivalent like 'Figtree' or 'Inter')

## Capabilities

### New Capabilities
- `spotify-home-feed`: Spotify-style home screen with user avatar, filter chips, 2-column quick-access grid, and horizontal "Jump back in" carousels
- `spotify-search-browse`: Spotify-style search screen with rounded search bar and colorful 2-column browse category cards
- `spotify-library-view`: Spotify-style library with filter chips, sort controls, and playlist/album list with square thumbnails
- `spotify-now-playing`: Full-screen now-playing with large artwork, context header, seek slider, Spotify transport controls, and action bar
- `spotify-mini-player`: Spotify-style persistent mini-player bar with album art, track info, and inline controls
- `spotify-navigation`: 5-tab bottom navigation matching Spotify's layout (Home, Search, Your Library, Premium, Create)
- `spotify-design-system`: Core design tokens, color palette, typography, spacing, and component styles matching the Spotify aesthetic

### Modified Capabilities
_(none — this is a pure frontend visual redesign; no backend API or data model changes)_

## Impact

- **Frontend files**: `backend/public/index.html`, `backend/public/styles.css`, `backend/public/app.js` — all three files will be substantially rewritten
- **Backend**: No changes — all existing API endpoints (`/api/songs`, `/api/stream/:id`, `/api/playlists`, etc.) remain unchanged
- **Assets**: May need new icons or updated manifest for the rebrand
- **PWA**: `manifest.json` and `sw.js` remain functionally the same; theme-color may update
- **Dependencies**: No new npm packages; this is a pure HTML/CSS/JS frontend overhaul
