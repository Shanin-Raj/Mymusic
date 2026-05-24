# android-twa-shell Specification

## Purpose
TBD - created by archiving change migrate-and-android-convert. Update Purpose after archive.
## Requirements
### Requirement: TWA Native Handshake
The system SHALL provide a native-to-web verification mechanism using the Digital Asset Links protocol on the current production domain.

#### Scenario: Verification request
- **WHEN** the Android OS requests the `/.well-known/assetlinks.json` file from the production URL
- **THEN** the server SHALL return a valid JSON object containing the SHA256 fingerprint of the app's signing certificate

### Requirement: Full-Screen Native Mode
The system SHALL support launching in a native "Standalone" mode that removes all browser chrome (URL bars, navigation buttons) when opened from the Android home screen.

#### Scenario: App Launch
- **WHEN** the user taps the app icon on an Android device
- **THEN** the system SHALL load the PWA in a full-screen view identical to a native application

