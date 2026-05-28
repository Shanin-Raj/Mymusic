## Why

When testing the downloaded Flutter APK on a real device, the app shows a `SocketException: Connection refused` error trying to access `http://localhost:8080/api/songs`. This occurs because `localhost` refers to the Android device itself, not the backend server. We need to point the app to the deployed production backend so it can load data and stream music correctly on physical devices.

## What Changes

- **Update API Base URL**: Change the hardcoded `baseUrl` in `flutter_app/lib/services/api_service.dart` from `http://localhost:8080` to the deployed Google Cloud Run URL: `https://music-vault-767870933282.asia-south1.run.app`.

## Capabilities

### Modified Capabilities
- `flutter-api-service`: Update the networking configuration to point to the remote production backend instead of the local development server.

## Impact

- The Flutter app will be able to fetch library data and stream audio from the actual backend when running on real Android devices or emulators without port forwarding.
- Data and functionality will exactly mirror the production web app.
