## Why

The application is currently experiencing two critical issues: 
1. The "song adding" feature is failing due to persistent Telegram connection timeouts (`ETIMEDOUT`), preventing users from adding new tracks to their vault.
2. The intended Spotify-inspired UI redesign has not been fully applied, leaving the application with its legacy "Bright Editorial" visual style which lacks the dark mode and familiar patterns users expect.

## What Changes

- **Backend Robustness**: Update `telegram.js` to implement more resilient connection handling for the GramJS client, including better retry strategies and handling of specific DC connection errors.
- **UI Redesign Application**: Fully transition the frontend (`index.html`, `styles.css`, `app.js`) to the Spotify-style dark UI, incorporating the dark color palette (#121212), 5-tab navigation, and album-art-rich layout.
- **Error Feedback**: Improve frontend error reporting when song adding fails (addressing the "code error 1" report) to provide actionable feedback to the user.

## Capabilities

### New Capabilities
- `telegram-resilience`: Robust Telegram connection management with intelligent retries and DC-specific handling to overcome network timeouts.
- `spotify-ui-integration`: Implementation of the Spotify-themed design system across all application screens, including the dark theme and standard navigation patterns.

### Modified Capabilities
- `song-adding-feedback`: Enhanced end-to-end feedback for the song adding flow, ensuring errors are caught and communicated clearly to the UI.

## Impact

- **Backend**: `backend/telegram.js` and `backend/main.js` will be updated for better error handling and connection stability.
- **Frontend**: `backend/public/index.html`, `backend/public/styles.css`, and `backend/public/app.js` will undergo significant updates to apply the new design and improved feedback loops.
- **Dependencies**: Potential configuration changes for the `telegram` npm package.
