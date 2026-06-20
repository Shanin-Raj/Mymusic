## 1. Rethink and Research

- [x] 1.1 Verify the exact manifest requirements for `audio_service` version 0.18.12.
- [x] 1.2 Confirm if `android:foregroundServiceType="mediaPlayback"` is required for the current target SDK.

## 2. Isolation Configuration

- [x] 2.1 Update `applicationId` in `flutter_app/android/app/build.gradle.kts` to `com.example.sonic_vault_flutter.dev` (or similar) to prevent overwriting the TWA app.
- [x] 2.2 Update the `namespace` in `build.gradle.kts` to match the development ID.

## 3. Manifest Fixes

- [x] 3.1 Add `<uses-permission android:name="android.permission.INTERNET" />` to `AndroidManifest.xml`.
- [x] 3.2 Add the mandatory `com.ryanheise.audioservice.AudioService` `<service>` declaration.
- [x] 3.3 Add the mandatory `com.ryanheise.audioservice.MediaButtonReceiver` `<receiver>` declaration.
- [x] 3.4 Ensure `android:label` in the manifest is set to "Mixtape Dev".

## 4. Verification

- [x] 4.1 Run `flutter clean`.
- [x] 4.2 Build the release APK.
- [x] 4.3 Install the APK on a device and verify it can coexist with the original app and launches without crashing.
