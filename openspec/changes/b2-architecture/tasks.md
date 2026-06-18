## 1. Backend Setup & Dependencies
- [x] 1.1 Install `@aws-sdk/client-s3` and `@aws-sdk/s3-request-presigner` in the Node.js backend.
- [x] 1.2 Add B2 environment variables (`B2_REGION`, `B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_BUCKET_NAME`, `B2_ENDPOINT`) to `.env`.

## 2. Upload & Signing Logic
- [x] 2.1 Create `s3.js` to initialize the `S3Client` and export upload and pre-signing functions.
- [x] 2.2 Modify the `addSong` function in `adder.js` to upload the downloaded audio buffer to the private Backblaze B2 bucket instead of Telegram.
- [x] 2.3 Store the B2 object key as `fileKey` (e.g. `${trackId}.m4a`) in Firestore.

## 3. Migration
- [x] 3.1 Create `migrate_to_b2.js` to download all existing songs from Telegram and upload them to the private B2 bucket, updating their documents in Firestore with `fileKey`.
  - *Note:* Exposed via `/api/admin/migrate-to-b2` HTTP endpoint to allow running it on Cloud Run since local connections to Telegram DC time out.

## 4. Backend Streaming & Cleanup
- [x] 4.1 Update `/api/stream/:id` in `server.js` to generate a pre-signed URL and redirect the client with a 302 redirect.
- [x] 4.2 Delete the local caching logic (`/tmp/music-cache`) and download queue from `server.js`.
- [x] 4.3 Delete `telegram.js` and uninstall the `telegram` package (migration complete!).

## 5. Verification
- [x] 5.1 Test adding a new song and verify it uploads to B2.
- [x] 5.2 Verify playback in the Flutter app streams directly from B2 with no stuttering.
