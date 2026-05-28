## Why

The universal library song adder was failing silently in production due to Google Cloud Run serverless CPU suspension. The persistent Telegram connection was being dropped, causing sockets to hang and timeout during manual additions. This change deploys robust fresh-connection handling to the active production backend and finalizes the manual addition feature in the library.

## What Changes

- Overhaul backend Telegram socket handling to use ephemeral, short-lived fresh connections that cleanly disconnect and destroy resources after uploads or deletions.
- Deploy the updated container image directly to the active `music-vault` service in `asia-south1`.
- Optimize the Cloud Build pipeline by adding `flutter_app/` and IDE directories to `.gcloudignore`, reducing bundle uploads from 2.4 GB to 74 MB and reducing build time to a few seconds.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `universal-library-adder`: Overhaul backend connection reliability to ensure manual syncs complete within Cloud Run CPU suspension limits.

## Impact

- **Backend API**: `/api/add-song` and `/api/songs/:id` (delete) endpoints in `server.js`, `adder.js`, and `telegram.js`.
- **Infrastructure**: Google Cloud Build config (`.gcloudignore`) and active Cloud Run deployment configuration.
