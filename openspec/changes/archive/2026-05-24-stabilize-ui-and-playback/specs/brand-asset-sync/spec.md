## ADDED Requirements

### Requirement: Unified Branding
The system SHALL use "Sonic Vault" as the application name across all platform metadata (HTML title, PWA manifest, Android TWA manifest) and use the vinyl record logo (`/assets/logo.jpg`) for all launcher and splash screen icons.

#### Scenario: Verify naming in Web PWA
- **WHEN** the user opens the web application
- **THEN** the browser tab title and the installed app name SHALL display "Sonic Vault"

#### Scenario: Verify logo in Android APK
- **WHEN** the Android application is installed
- **THEN** the launcher icon SHALL show the vinyl record design
