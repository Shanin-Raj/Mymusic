## 1. Network Configuration

- [x] 1.1 In `d:\music\flutter_app\lib\services\api_service.dart`, locate the `baseUrl` variable.
- [x] 1.2 Change its value from `'http://localhost:8080'` to `'https://music-vault-767870933282.asia-south1.run.app'`.

## 2. Verification

- [x] 2.1 Rebuild the release APK using `flutter build apk --release`.
- [x] 2.2 Reinstall the APK on the device and verify that the "Your Library" screen loads the songs instead of showing a `Connection refused` error.
