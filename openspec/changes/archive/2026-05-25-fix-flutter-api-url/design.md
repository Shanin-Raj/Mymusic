## Context

The Flutter application was using `http://localhost:8080` as its API base URL during local development in the emulator. However, when the app is packaged as a release APK and installed on a physical Android device, `localhost` resolves to the phone itself, which is not running the Node.js backend. This results in a `SocketException: Connection refused`.

## Goals / Non-Goals

**Goals:**
- Fix the `SocketException` on app launch.
- Enable the Flutter app to fetch the real music library and stream songs from the production server.

**Non-Goals:**
- Setting up complex environments (Dev/Staging/Prod) using `.env` files for Flutter (we'll just hardcode the production URL for now for simplicity, as requested by the immediate need).

## Decisions

- **Direct Hardcode vs Environment Variables**: Given the urgency of testing the app on the device, we will directly update the `baseUrl` string in `api_service.dart`. Environment variable setup in Flutter (like `flutter_dotenv`) adds unnecessary complexity at this stage of testing.

## Risks / Trade-offs

- **Risk**: Hardcoding the production URL means local emulator tests will now also hit the production server instead of a local Node.js instance.
- **Mitigation**: This is acceptable since the production backend is read-heavy for clients (mostly fetching songs and streaming) and it perfectly simulates the real user experience. If local testing is needed again later, the developer can temporarily revert it or we can set up flavors.
