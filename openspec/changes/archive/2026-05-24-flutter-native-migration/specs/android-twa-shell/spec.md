## REMOVED Requirements

### Requirement: TWA Native Handshake
**Reason**: The application is no longer a PWA wrapped in a Trusted Web Activity. It is now a fully native Flutter application.
**Migration**: Remove the `.well-known/assetlinks.json` verification dependency for the Android client. The Flutter app will communicate directly with APIs.

### Requirement: Full-Screen Native Mode
**Reason**: Replaced by native Flutter rendering.
**Migration**: The Flutter engine inherently manages the UI without browser chrome. Remove TWA `manifest.json` configurations related to display modes.