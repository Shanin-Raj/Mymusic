## 1. Android Manifest Permissions

- [x] 1.1 Add `<uses-permission android:name="android.permission.WAKE_LOCK"/>` to `android/app/src/main/AndroidManifest.xml`.
- [x] 1.2 Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>` to `android/app/src/main/AndroidManifest.xml`.
- [x] 1.3 Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />` to `android/app/src/main/AndroidManifest.xml`.

## 2. Android Service Registration

- [x] 2.1 Inside the `<application>` tag in `AndroidManifest.xml`, add the `<service>` declaration for `com.ryanheise.audioservice.AudioService` with `android:foregroundServiceType="mediaPlayback"`.
- [x] 2.2 Ensure the service is `exported="true"` and has the intent filter for `android.intent.action.MEDIA_BUTTON`.

## 3. Notification Icon Verification

- [x] 3.1 Check if a valid silhouette notification icon exists in `android/app/src/main/res/drawable/` or `drawable-*/`. Create or adapt one if missing.
