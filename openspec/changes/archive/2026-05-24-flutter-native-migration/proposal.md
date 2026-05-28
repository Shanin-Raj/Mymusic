## Why

The current Android application relies on a Trusted Web Activity (TWA) wrapper, which has critical limitations regarding background audio playback and reliable lockscreen controls. To solve these issues and provide a truly native experience, we need to rebuild the app in Flutter while preserving the existing backend infrastructure. This migration must be seamless for users, replacing the current TWA app through a standard update process without downtime.

## What Changes

- **Parallel Flutter Development**: We will create a fresh, isolated Flutter project that mirrors the existing HTML/CSS UI without touching the live Bubblewrap project or its keystore.
- **Backend Re-integration**: The new Flutter app will connect to the existing Firebase and Node.js backend (with Render migration in mind).
- **Native Android Switch**: We will change the Flutter app's `applicationId` to match the original TWA app and sign it with the exact same Keystore.
- **BREAKING**: The TWA wrapper and its associated web manifest configurations for Android display will be entirely replaced by a native Flutter compilation.

## Capabilities

### New Capabilities
- `flutter-native-app`: A parallel, isolated native Flutter implementation replicating the current PWA UI and functionality, connecting to the same Firebase backend.
- `flutter-audio-service`: A native background audio playback service within Flutter to replace the web-based MediaSession API.

### Modified Capabilities
- `android-twa-shell`: The requirement for a TWA shell is removed and replaced by the Flutter engine wrapping the application logic.
- `background-audio-continuity`: Requirements shift from web-based media sessions to native Flutter background audio execution.

## Impact

- **Code**: A new `flutter_app/` directory will be created alongside the `backend/` and `public/` web directories.
- **APIs**: The Flutter app will communicate with the existing Node.js APIs and Firebase just like the PWA.
- **Systems**: The Android build pipeline will shift from Bubblewrap to standard Flutter Android compilation using the existing keystore.