
## 1. Project Initialization & Architecture

- [x] 1.1 Create a new Flutter project in `flutter_app/` at the root of the workspace.
- [x] 1.2 Add necessary dependencies (`http`, `just_audio`, `audio_service`, `shared_preferences`) to `flutter_app/pubspec.yaml`.
- [x] 1.3 Establish a centralized `ThemeData` to replicate the PWA's dark/light modes and CSS variables (e.g., `--bg`, `--primary`).

## 2. API & Data Integration

- [x] 2.1 Create an API service class in Flutter to communicate with the existing Node.js endpoints (handling songs, playlists, pre-caching).
- [x] 2.2 Migrate the `sv_songs_cache` logic from `localStorage` to `shared_preferences` or a local SQLite/Hive database in Flutter.
- [x] 2.3 Ensure API URLs are configurable to support the eventual migration to Render.

## 3. UI Translation

- [x] 3.1 Replicate the Home Feed screen with the horizontal mix carousels and recent grids.
- [x] 3.2 Replicate the Library View with the vertical track list and swipe-to-delete functionalities.
- [x] 3.3 Replicate the persistent Bottom Navigation Bar and the Mini Player overlay.
- [x] 3.4 Build the Full Screen Player sliding up over the UI with identical transport controls and progress bars.

## 4. Native Background Audio Service

- [x] 4.1 Initialize `audio_service` with a custom `BaseAudioHandler` to manage queue state independent of the UI.
- [x] 4.2 Integrate `just_audio` within the audio handler to play the `/api/stream/{id}` URLs.
- [x] 4.3 Map Flutter's media action callbacks (`play`, `pause`, `skipToNext`, `skipToPrevious`, `seek`) to the native audio handler.
- [x] 4.4 Implement the 45-second predictive pre-caching logic within the audio handler.

## 5. The Native Switch (Android Configuration)

- [x] 5.1 Locate the exact `applicationId` from the original Bubblewrap project (`android/app/build.gradle`) and update `flutter_app/android/app/build.gradle` to match perfectly.
- [x] 5.2 Configure the release signing block in `flutter_app/android/app/build.gradle` to use the existing `android/android.keystore` file (without moving or modifying the original file).
- [x] 5.3 Ensure `minSdkVersion` and `targetSdkVersion` match standard modern requirements.
- [x] 5.4 Build the Flutter Android release bundle (`flutter build appbundle`) and verify signatures.