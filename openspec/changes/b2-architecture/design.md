## Context

The app currently uses a "Proxy/Middleman" approach where the Node.js backend downloads media from a private Telegram channel and streams it to the Flutter app. We are migrating to a Production-Ready architecture using Backblaze B2 as an S3-compatible cloud storage provider.

## Goals

- Eliminate audio stuttering and playback lag.
- Bypass the Render/Node.js server for media streaming.
- Provide a robust, ban-free media storage solution.
- **Strict Constraint:** Avoid requiring a credit card for setup (Free Tier).

## Decisions

**1. Cloud Storage Provider and Privacy:**
*Decision:* Use Backblaze B2 with a **Private** bucket.
*Rationale:* Public buckets in Backblaze B2 require a credit card for identity verification. Private buckets do not. We can keep the bucket private and still stream directly to the client using temporary pre-signed URLs.

**2. Pre-signed Redirect URLs:**
*Decision:* Generate temporary pre-signed URLs on the Node.js backend using `@aws-sdk/s3-request-presigner` and return an `HTTP 302 Found` redirect.
*Rationale:* When the Flutter app requests `/api/stream/:id`, the backend generates a pre-signed GET URL for B2 that is valid for 1 hour. It returns a 302 redirect. The Flutter app follows the redirect automatically, allowing it to stream directly from Backblaze B2's CDN. No credentials or changes are needed in the Flutter client code.

**3. Backend Upload Logic:**
*Decision:* Replace `telegram.js` with direct S3 uploads using `@aws-sdk/client-s3`.
*Rationale:* When a song is added, Node.js downloads it and pushes it straight to Backblaze using standard S3 protocol commands (`PutObjectCommand`).

**4. Database Updates:**
*Decision:* Store the B2 key as `fileKey` (e.g. `${song.id}.m4a`) in Firestore.
*Rationale:* Allows the Node.js backend to easily construct the correct object key to generate pre-signed URLs.

**5. Backend Streaming Logic Deletion:**
*Decision:* Delete the local caching (`/tmp/music-cache`) and the custom streaming logic in `/api/stream/:id` from `server.js`.
*Rationale:* B2 handles streaming and HTTP Range requests natively via the pre-signed URL, making backend streaming obsolete.

## Risks / Trade-offs

- **Risk:** Existing songs stored in Telegram will become unplayable unless migrated.
  *Mitigation:* We will write a migration script (`migrate_to_b2.js`) to move existing audio from Telegram to B2, keeping Telegram code intact until migration is complete, then deleting it.
- **Trade-off:** Node.js backend needs to perform a quick signing handshake on request.
  *Mitigation:* Pre-signing is a purely mathematical/cryptographic operation that requires no network call. It takes less than 1 millisecond and has zero overhead.
