## Context

The current Android application is a Progressive Web App (PWA) wrapped as a Trusted Web Activity (TWA) using Bubblewrap. While this allowed for a rapid initial release, the TWA wrapper fundamentally struggles with native Android background audio continuity and reliable lockscreen media controls. To achieve the high-fidelity playback expected from a premium music app, a native client is required. The chosen path is a 3-Phase Engineering Blueprint: protecting the live TWA project, building a parallel Flutter app, and executing a native switch.

## Goals / Non-Goals

**Goals:**
- Architect a clean, isolated Flutter project that perfectly replicates the current HTML/CSS UI.
- Establish robust background audio playback and lockscreen media controls using Flutter native packages.
- Connect the Flutter app to the existing Node.js APIs and Firebase infrastructure.
- Provide a seamless update path for existing Android users by adopting the original `applicationId` and signing the build with the original Keystore.

**Non-Goals:**
- Modifying or rewriting the existing Node.js backend or Firebase data structures.
- Changing the UI/UX design (the goal is a 1:1 replication of the current Spotify-style interface).
- Decommissioning the PWA (the web version will remain active for desktop and non-Android users).

## Decisions

- **Decision 1: Isolated Flutter Project Workspace**
  - *Rationale*: To guarantee zero interference with the live Bubblewrap Android build, the Flutter project will be scaffolded in a completely separate directory (`flutter_app/`) at the root of the workspace.
  - *Alternatives*: Integrating Flutter into the existing `android/` directory was rejected due to high risk of build configuration conflicts and breaking the fallback TWA.

- **Decision 2: Native Audio Packages (`just_audio` & `audio_service`)**
  - *Rationale*: These packages are the industry standard in the Flutter ecosystem for handling robust background audio execution and integrating deeply with Android's MediaSession API (lockscreen, headphones, notifications).
  - *Alternatives*: Writing custom platform channels to native Kotlin ExoPlayer was rejected to minimize maintenance overhead, as existing packages already solve this reliably.

- **Decision 3: Seamless Keystore Migration**
  - *Rationale*: To ensure Google Play (or direct APK updates) recognize the new Flutter app as a valid update to the existing TWA app, we must use the exact same `android.keystore` and `applicationId` (e.g., `com.musicvault.twa` or similar). The Flutter `android/app/build.gradle` will be configured to point to the existing keystore file.

## Risks / Trade-offs

- **Risk: Signature Mismatch** → *Mitigation*: We will strictly audit the `applicationId` and Keystore configuration before generating the release bundle. We will not modify the original `android.keystore` file.
- **Risk: UI translation inaccuracies** → *Mitigation*: The Flutter implementation will meticulously translate the existing CSS variables (e.g., `--primary: #53e076`, `--bg: #000000`) into a centralized Flutter `ThemeData` to ensure pixel-perfect fidelity.
- **Risk: API Authentication bridging** → *Mitigation*: The Flutter app will utilize the same REST API endpoints and Firebase authentication flows, ensuring user sessions remain consistent.

## Migration Plan

1. Scaffold the Flutter project in `flutter_app/`.
2. Recreate the UI and integrate API connections.
3. Implement `audio_service` for playback.
4. Update `flutter_app/android/app/build.gradle` with the target `applicationId`.
5. Configure signing blocks to use the existing `android/android.keystore`.
6. Compile the release AAB/APK and deploy as an update to the current user base.