## Why

The `main.js` script (which processes Spotify playlists) fails during execution with a `Telegram credentials not configured` error, even though `manual_add.js` works perfectly. This happens because `main.js` does not load the environment variables from the `.env` file on startup.

## What Changes

- **Add `dotenv` Import**: Include the `dotenv` configuration line at the very top of `main.js` to ensure `TELEGRAM_API_ID` and other secrets are loaded into `process.env` before the script attempts to connect to Firebase or Telegram.

## Capabilities

### Modified Capabilities
- `main-js-env`: Fix the backend environment loading logic to mirror `manual_add.js`.

## Impact

- `main.js` will be able to process full Spotify playlists again without throwing credential errors.
