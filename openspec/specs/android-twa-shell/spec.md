# android-twa-shell Specification

## Purpose
This capability was previously used for the TWA shell. It has been replaced by the native Flutter application (see `flutter-native-app`).

## Requirements
### Requirement: TWA Native Handshake (REMOVED)
**Reason**: The application is no longer a PWA wrapped in a Trusted Web Activity. It is now a fully native Flutter application.
**Migration**: Remove the `.well-known/assetlinks.json` verification dependency for the Android client. The Flutter app will communicate directly with APIs.

### Requirement: Full-Screen Native Mode (REMOVED)
**Reason**: Replaced by native Flutter rendering.
**Migration**: The Flutter engine inherently manages the UI without browser chrome. Remove TWA `manifest.json` configurations related to display modes.
