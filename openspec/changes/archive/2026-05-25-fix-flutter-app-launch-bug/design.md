## Context

The Flutter application is crashing on launch in release mode. We must fix this while strictly adhering to the "isolation" principle: the experimental Flutter app should not replace the working TWA app yet. We will incorporate a "Rethink" phase before execution to verify our assumptions.

## Goals / Non-Goals

**Goals:**
- Fix the launch crash by adding missing manifest components and permissions.
- Ensure the Flutter app has a unique `applicationId` to prevent merging with TWA prematurely.
- Verify manifest syntax and service requirements before code changes.

**Non-Goals:**
- Merging with the production TWA `applicationId`.
- Reusing the production keystore for these intermediate development builds.

## Decisions

- **Decision 1: Rethink Manifest Logic**
  - *Assumptions*: `audio_service` 0.18.x requires a foreground service and internet permissions for release builds.
  - *Checkpoint*: We will cross-reference the official package documentation before applying XML changes.

- **Decision 2: Unique Application ID for Development**
  - *Rationale*: To allow parallel installation of both the PWA-TWA and the Native Flutter app, the Flutter app must use a unique ID (e.g., `com.example.sonic_vault_flutter.dev`).
  - *Constraint*: The switch to the TWA ID will only happen in Phase 3 after the Flutter app is 1:1 with the web app.

- **Decision 3: Cleartext Traffic for Local Testing**
  - *Rationale*: If the backend is accessed via IP or localhost without SSL during dev, we must enable `android:usesCleartextTraffic="true"`.

## Risks / Trade-offs

- **Risk: Premature Merge** → *Mitigation*: Strictly keep the `applicationId` different from the TWA one.
- **Risk: Build cache pollution** → *Mitigation*: Always run `flutter clean` after manifest or ID changes.

## Migration Plan

1. **Rethink Phase**: Review the `audio_service` requirements.
2. **Isolation Phase**: Update `build.gradle.kts` to use a non-conflicting `applicationId`.
3. **Fix Phase**: Add permissions and service tags to `AndroidManifest.xml`.
4. **Verification Phase**: Build and test APK alongside the existing app.
