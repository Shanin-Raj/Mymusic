## Why

The current architecture relies on Telegram's MTProto API as a free storage backend. While clever, this approach forces the Node.js server to act as a middleman, downloading audio from Telegram, caching it locally, and streaming it to the Flutter app. This creates severe bandwidth bottlenecks, introduces wake-up latency, and exposes the app to Telegram rate limits and MTProto session expirations.

## What Changes

We are migrating our primary media storage from Telegram to Backblaze B2 (an S3-compatible object storage).
- The `yt-dlp` downloader will now upload directly to a **private** Backblaze B2 bucket instead of a Telegram channel.
- The Node.js backend streaming endpoint (`/api/stream/:id`) will generate a temporary pre-signed URL on-the-fly and return an `HTTP 302 Found` redirect.
- The Flutter client will follow the redirect automatically and stream audio directly from Backblaze B2, completely bypassing the Node.js server's network bandwidth.
- We will use the `@aws-sdk/client-s3` and `@aws-sdk/s3-request-presigner` packages in Node.js to communicate with Backblaze B2.

## Impact

- **Performance:** Massive improvement. Zero server wake-up lag and flawless buffering since B2 natively supports HTTP Range requests.
- **Reliability:** Eliminates stuttering and eliminates the risk of Telegram bans.
- **Backend Code:** Significant reduction in complexity. We can delete `telegram.js`, local disk caching logic, and the manual stream piping in `server.js`.
- **Cost:** Free. B2 provides 10GB of free storage and private buckets require no credit card for verification.
