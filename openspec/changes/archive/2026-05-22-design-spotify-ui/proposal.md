## Why

The current "Sonic Vault" UI, while functional, lacks the premium aesthetic and brand recognition of industry leaders like Spotify. By adopting Spotify's official design guidelines, we can provide users with a familiar, professional-grade interface that emphasizes high-quality metadata, content-focused layouts, and intuitive component behavior. This will enhance the overall user experience and align the app with modern streaming standards.

## What Changes

- **Visual Theme**: Complete transition to Spotify's signature dark aesthetic, utilizing **Spotify Green (#1FDF64)** as the primary brand color on high-contrast black/dark backgrounds.
- **Typography**: Shift to platform-native sans-serif fonts for maximum legibility and a "system" feel.
- **Layout Refinements**:
  - Implement a cleaner, more focused "Now Playing" view with artwork-driven background gradients.
  - Standardize album artwork corner radii (4px/8px) for optimal optical blending.
  - Optimize metadata display (titles, artists) to respect character constraints and prevent layout breaking.
- **Component Behavior**:
  - Update the "Like" feature to use the official **"+" icon** instead of the current heart icon.
  - Redesign playback controls and progress bars to match Spotify's minimalist and informational standards.
  - Add explicit content badges where applicable.
- **Deployment**: Full rebuild and deployment of the updated UI to the existing Cloud Run service (`music-vault-shanin`).

## Capabilities

### New Capabilities
- `spotify-ui-redesign`: A comprehensive overhaul of the frontend visual identity and component architecture following Spotify's official Branding & Design guidelines.

### Modified Capabilities
- None: This is a purely visual and structural redesign; core streaming and backend logic remain unchanged.

## Impact

- **Frontend Assets**: Major breaking changes to `backend/public/styles.css` and structural updates to `backend/public/index.html`.
- **UI Logic**: Refinement of rendering functions in `backend/public/app.js` to support new component states and layouts.
- **Deployment Pipeline**: Requires a new Cloud Build and Cloud Run revision deployment.
- **User Experience**: Drastic improvement in visual polish and navigation familiarity.
