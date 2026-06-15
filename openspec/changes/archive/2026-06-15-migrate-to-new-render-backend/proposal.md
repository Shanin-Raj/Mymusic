## Why

1. **Render Free Tier Exhaustion:** Having multiple apps (mixtape-backend, TrueFit, Fitness_Tracker) running continuously on a single free Render account exceeded the 750-hour free workspace limit. Deploying `mixtape-backend` on a dedicated separate Render account provides a fresh 750-hour monthly pool.
2. **Firestore Undefined Crash:** The CLI adder crashed when trying to save track documents to Firestore where the `image` field was `undefined` due to Spotify/YouTube metadata parsing limitations.
3. **Stale Memory Cache:** The backend API server (`server.js`) had a permanent memory cache that did not get invalidated when tracks were added via the separate CLI process, leaving new additions invisible in the app until a server reboot.

## What Changes

- **Hosting & API Endpoints:**
  - Migrated the backend hosting instance to `https://mymusic-ibgr.onrender.com`.
  - Configured `FIREBASE_KEY_JSON` environment variable in Render as a minified, single-line JSON string to prevent escaping syntax errors during parsing.
- **Backend Code fixes:**
  - Configured Firestore client to ignore undefined properties (`db.settings({ ignoreUndefinedProperties: true })`).
  - Added safe `image || null` fallback handling in `spotify.js` and `manual_add.js` mapping.
  - Implemented 30-second TTL cache invalidation logic for `songsCache` and `playlistsCache` in `server.js` (`getLibrary` and `getPlaylists`).
- **Client Configuration Updates:**
  - Modified `baseUrl` in Flutter API client (`flutter_app/lib/services/api_service.dart`) to the new Render endpoint.
  - Updated web app manifest `related_applications` URL in `backend/public/manifest.json`.
  - Re-mapped the `host`, `iconUrl`, `maskableIconUrl`, `webManifestUrl`, and `fullScopeUrl` properties in Trusted Web Activity descriptor (`android/twa-manifest.json`).

## Capabilities

### Modified Capabilities
- `deployment`: Backend migrated to a new Render web service, environment variable schemas updated.
- `database-layer`: Configured Firestore tolerance for undefined attributes, metadata scrapers normalized to null images.
- `caching-layer`: Integrated cache expiration (TTL of 30 seconds) in memory-cached collections to sync API responses with database insertions.
