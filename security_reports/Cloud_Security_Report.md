# Cloud Security Audit — Database & Storage Integration
**Target:** Sonic Vault Backend (Node.js / Express)  
**Scope:** Backblaze B2 (S3-Compatible Storage) · Cloud Firestore · Credential Hygiene  
**Date:** June 18, 2026  
**Status:** DRAFT — Pending Remediation

---

## 1. Executive Summary

The Sonic Vault backend delegates all persistent data to two cloud services:

| Service | Role | SDK | Credential Type |
|---|---|---|---|
| **Cloud Firestore** | Song catalog, playlist state, listening room sync | `firebase-admin` (server-side) | Service Account Key (JSON) |
| **Backblaze B2** | Private `.m4a` audio file storage | `@aws-sdk/client-s3` + `s3-request-presigner` | Application Key (`B2_KEY_ID` / `B2_APPLICATION_KEY`) |

The architecture is **server-mediated** — the Flutter mobile client never touches Firestore or B2 directly. All data flows through the Express API. This is architecturally sound, but the current implementation contains **six distinct vulnerabilities** across credential management, storage access control, data leakage, and missing server-side validation.

---

## 2. Vulnerability Report

### 🔴 CRITICAL — V1: Firebase Service Account Key Committed to Git History

**File:** `backend/firebase-key.json`  
**Evidence:**
```
$ git log --all --oneline -- backend/firebase-key.json
e2b535b security: untrack firebase-key.json
20d1829 Initialize project for migration with robust .gitignore
```

The full Firebase Admin SDK service account private key was committed in `20d1829` and only removed from tracking in `e2b535b`. The `.gitignore` now excludes it, but **the key remains permanently readable in git history**. Anyone who clones this repository (or has cloned it at any point) can extract the key and gain **full admin access** to Cloud Firestore — read, write, and delete all collections (`songs`, `playlists`, `rooms`).

**Impact:** Complete database takeover. An attacker can wipe the entire song catalog, exfiltrate all user data, or inject malicious room states.

**Remediation:**
1. **Rotate the key immediately** in the Firebase Console → Project Settings → Service Accounts → Generate New Private Key.
2. **Rewrite git history** to purge the old key using `git filter-repo` or BFG Repo Cleaner:
   ```bash
   # Install BFG (https://rtyley.github.io/bfg-repo-cleaner/)
   bfg --delete-files firebase-key.json
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force
   ```
3. **Verify** by running: `git log --all --diff-filter=A -- backend/firebase-key.json` — should return nothing after the rewrite.

---

### 🔴 CRITICAL — V2: Backblaze B2 Application Key Has Excessive Permissions (Likely Master Key)

**File:** [s3.js](file:///d:/music/backend/s3.js) · [.env](file:///d:/music/backend/.env)

The B2 key ID `d98db60cfeff` is used for **all operations**: `PutObject`, `GetObject`, `DeleteObject`, and pre-signed URL generation. There is no evidence of key scoping. The `.env` uses `B2_APPLICATION_KEY` which, based on the naming and the fact that a single key handles both uploads and deletes, is very likely the **Master Application Key** or a key with full bucket read/write/delete permissions.

**Impact:** If the backend server is compromised (e.g., via the argument injection found in the SAST report), the attacker gains unrestricted access to the entire B2 bucket — they can download every audio file, delete the entire library, or upload malicious content.

**Remediation — Apply Principle of Least Privilege:**

Create **two scoped B2 Application Keys** in the Backblaze console:

| Key Purpose | Capabilities | Scope |
|---|---|---|
| **Runtime Key** (used by `server.js`) | `listFiles`, `readFiles` | Bucket: `MixtapeCloud` only |
| **Admin Key** (used by `adder.js` upload + delete) | `writeFiles`, `deleteFiles`, `listFiles`, `readFiles` | Bucket: `MixtapeCloud` only |

Then update `.env`:
```env
# Runtime (read-only, used for streaming pre-signed URLs)
B2_READ_KEY_ID=<scoped-read-key-id>
B2_READ_APPLICATION_KEY=<scoped-read-key>

# Admin (write/delete, used only by add-song and delete-song)
B2_ADMIN_KEY_ID=<scoped-admin-key-id>
B2_ADMIN_APPLICATION_KEY=<scoped-admin-key>
```

Updated `s3.js` with dual-client architecture:

```javascript
const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// READ-ONLY client — used for generating pre-signed stream URLs
const readClient = new S3Client({
    endpoint: `https://${process.env.B2_ENDPOINT}`,
    region: process.env.B2_REGION || 'us-east-005',
    credentials: {
        accessKeyId: process.env.B2_READ_KEY_ID,
        secretAccessKey: process.env.B2_READ_APPLICATION_KEY
    }
});

// ADMIN client — used for uploads and deletes only
const adminClient = new S3Client({
    endpoint: `https://${process.env.B2_ENDPOINT}`,
    region: process.env.B2_REGION || 'us-east-005',
    credentials: {
        accessKeyId: process.env.B2_ADMIN_KEY_ID,
        secretAccessKey: process.env.B2_ADMIN_APPLICATION_KEY
    }
});

const BUCKET = process.env.B2_BUCKET_NAME;

async function uploadToB2(fileBuffer, key, mimeType = 'audio/mp4') {
    const command = new PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: fileBuffer,
        ContentType: mimeType
    });
    return await adminClient.send(command);
}

async function getPresignedUrl(key, expiresInSeconds = 900) {
    // HARDENED: Reduced from 3600s to 900s (15 minutes)
    const cappedExpiry = Math.min(expiresInSeconds, 900);
    const command = new GetObjectCommand({
        Bucket: BUCKET,
        Key: key
    });
    return await getSignedUrl(readClient, command, { expiresIn: cappedExpiry });
}

async function deleteFromB2(key) {
    const command = new DeleteObjectCommand({
        Bucket: BUCKET,
        Key: key
    });
    return await adminClient.send(command);
}

module.exports = { uploadToB2, getPresignedUrl, deleteFromB2 };
```

---

### 🟠 HIGH — V3: Pre-Signed URLs Have Excessive TTL (3600s / 1 Hour)

**File:** [server.js:209](file:///d:/music/backend/server.js#L209) · [s3.js:36](file:///d:/music/backend/s3.js#L36)

```javascript
// server.js line 209
const presignedUrl = await getPresignedUrl(key, 3600);

// s3.js line 36
async function getPresignedUrl(key, expiresInSeconds = 3600) {
```

Pre-signed URLs are generated with a **1-hour expiry**. Once a client receives this URL, it can be shared, bookmarked, or scraped. A 1-hour window means:
- The URL can be forwarded to unauthorized users who can download the file freely.
- If a URL is intercepted (e.g., via HTTP referer leak on an insecure page), the attacker has a large exploitation window.

**Impact:** Unauthorized file downloads. Each leaked URL grants unauthenticated access to a private audio file for 60 minutes.

**Remediation:** Reduce TTL to **15 minutes (900 seconds)** — more than enough for a mobile audio player to buffer and stream a track, but short enough to limit abuse.

```javascript
// server.js — updated stream endpoint
app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song) return res.status(404).json({ error: true, message: 'Not found' });

        const key = song.fileKey || `${song.id}.m4a`;
        const presignedUrl = await getPresignedUrl(key, 900); // 15 minutes
        res.redirect(302, presignedUrl);
    } catch (err) {
        console.error('Stream failed:', err);
        res.status(500).json({ error: true, message: 'Stream failed' });
    }
});
```

---

### 🟠 HIGH — V4: B2 `fileKey` Unsanitized — Path Traversal in Delete & Stream

**File:** [server.js:155](file:///d:/music/backend/server.js#L155) · [server.js:208](file:///d:/music/backend/server.js#L208)

```javascript
// Delete endpoint (line 155)
const fileKey = song.fileKey || `${song.id}.m4a`;
await deleteFromB2(fileKey);

// Stream endpoint (line 208)
const key = song.fileKey || `${song.id}.m4a`;
const presignedUrl = await getPresignedUrl(key, 3600);
```

The `fileKey` is read directly from the Firestore document and passed to B2 without any validation. While the current `adder.js` only writes keys in the format `{trackId}.m4a`, a compromised or manipulated Firestore document could contain a `fileKey` like `../../other-bucket-object` or a key belonging to another user's namespace.

More critically — the **delete endpoint** uses whatever `fileKey` is stored in the Firestore `song` document. If an attacker can write arbitrary data to a Firestore song document (which is possible with the leaked service account key from V1), they can cause the backend to **delete arbitrary objects** from B2.

**Impact:** Arbitrary file deletion from B2. Potential access to objects outside the expected namespace via path manipulation.

**Remediation:** Validate that `fileKey` matches the expected format before using it with B2:

```javascript
/**
 * Validates that a B2 file key matches the expected song file pattern.
 * Prevents path traversal and arbitrary key manipulation.
 */
function isValidFileKey(key) {
    // Must be: {alphanumeric/dash/underscore}.m4a — no slashes, no dots except extension
    return /^[a-zA-Z0-9_-]+\.m4a$/.test(key);
}

// In DELETE /api/songs/:id handler:
app.delete('/api/songs/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const song = await getSongById(id);
        if (!song) return res.status(404).json({ error: 'Not found' });

        const fileKey = song.fileKey || `${song.id}.m4a`;
        
        // SECURITY: Validate fileKey before sending to B2
        if (!isValidFileKey(fileKey)) {
            console.error(`🚨 SECURITY: Invalid fileKey "${fileKey}" for song ${id}. Skipping B2 delete.`);
        } else {
            try {
                await deleteFromB2(fileKey);
                console.log(`Deleted B2 object ${fileKey} for ${song.name}`);
            } catch (err) {
                console.warn(`B2 Delete Failed for ${id}:`, err.message);
            }
        }

        await db.collection('songs').doc(id).delete();
        
        const playlists = await db.collection('playlists').get();
        const batch = db.batch();
        playlists.forEach(doc => {
            const plData = doc.data();
            if (plData.songs && plData.songs.includes(id)) {
                const updatedSongs = plData.songs.filter(sid => sid !== id);
                batch.update(doc.ref, { songs: updatedSongs });
            }
        });
        await batch.commit();

        res.json({ status: 'ok' });
    } catch (err) {
        console.error('Delete song failed:', err);
        res.status(500).json({ error: 'Failed to delete song' });
    }
});

// In GET /api/stream/:id handler:
app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song) return res.status(404).json({ error: true, message: 'Not found' });

        const key = song.fileKey || `${song.id}.m4a`;

        if (!isValidFileKey(key)) {
            console.error(`🚨 SECURITY: Invalid fileKey "${key}" for song ${req.params.id}. Refusing stream.`);
            return res.status(400).json({ error: true, message: 'Invalid file reference' });
        }

        const presignedUrl = await getPresignedUrl(key, 900);
        res.redirect(302, presignedUrl);
    } catch (err) {
        console.error('Stream failed:', err);
        res.status(500).json({ error: true, message: 'Stream failed' });
    }
});
```

---

### 🟡 MEDIUM — V5: Firestore Data Over-Fetching — `fileKey` Leaked to Clients

**File:** [server.js:185-201](file:///d:/music/backend/server.js#L185-L201)

```javascript
// GET /api/songs — returns the full cache
const updatedSongs = songs.map(song => {
    // ...
    return {
        ...song,                    // <-- Spreads ALL Firestore fields
        image: getAbsoluteImageUrl(req, img)
    };
});
```

The spread operator (`...song`) returns **every field** from the Firestore document to the client, including:
- `fileKey` — the internal B2 object key (e.g., `0C47mkZ7VGcnKBvEG7PiAP.m4a`)
- `added_at` — server timestamp (minor, but unnecessary)

Exposing `fileKey` is a security concern because it reveals the internal naming scheme of B2 objects. Combined with knowledge of the B2 bucket name (which could be discovered via the pre-signed URL domain), an attacker could construct targeted attacks.

**Impact:** Information disclosure. Leaks internal storage keys to untrusted clients.

**Remediation:** Explicitly select only the fields the client needs:

```javascript
/**
 * Strips internal/sensitive fields from a song document before sending to client.
 */
function sanitizeSongForClient(song, req) {
    let img = song.image;
    if (!img || img === '') {
        img = getRandomCoverImage(song.id || song.name);
    }
    return {
        id: song.id,
        name: song.name,
        artist: song.artist,
        album: song.album,
        image: getAbsoluteImageUrl(req, img),
        duration_ms: song.duration_ms || null
    };
    // Deliberately EXCLUDES: fileKey, added_at, and any future internal fields
}

// Usage in GET /api/songs:
app.get('/api/songs', async (req, res) => {
    try {
        const songs = await getLibrary();
        const sanitized = songs.map(song => sanitizeSongForClient(song, req));
        res.json({ songs: sanitized, total: songs.length });
    } catch (err) {
        res.status(500).json({ error: true, message: 'Library failed' });
    }
});
```

Apply the same `sanitizeSongForClient()` function in **all** endpoints that return song data:
- `GET /api/songs` (line 185)
- `GET /api/songs/:id` (line 389)
- `GET /api/playlists/:id` (line 299 — inner song list)

---

### 🟡 MEDIUM — V6: Stale Credentials in `.env` — Telegram Tokens Still Present

**File:** [.env](file:///d:/music/backend/.env) (lines 3–8)

```env
TELEGRAM_BOT_TOKEN=7715076968:AAFEiPDgmavQ27ZGm8rUKxp2jBfD4JrZIWY
TELEGRAM_BOT_USERNAME=shanins_music_bot
TELEGRAM_API_ID=34768070
TELEGRAM_API_HASH=53c5955951e1489621e49d4cf4cc5c86
TELEGRAM_CHANNEL_ID=-1003934651159
```

The Telegram Bot Token, API credentials, and channel ID remain in the `.env` despite the migration to B2. While no backend code currently references them, the [render.yaml](file:///d:/music/render.yaml) deployment manifest also declares `TELEGRAM_*` environment variables (lines 10–19), meaning they are still injected into the production container.

**Impact:** Unnecessary attack surface. If the server is compromised, these credentials grant control of the Telegram bot and channel — potential for spam, data exfiltration, or social engineering.

**Remediation:**
1. Remove all `TELEGRAM_*` lines from `.env`.
2. Remove the corresponding entries from `render.yaml` (lines 10–19).
3. Revoke the Telegram Bot Token via `@BotFather` → `/revoke`.
4. Similarly, the `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` should be reviewed — if the Spotify scraper is still needed, keep them; otherwise, revoke and remove.

---

## 3. Firestore Security Posture

### Architecture Assessment: ✅ Acceptable (Server-Mediated)

The Flutter client app (`flutter_app/`) does **not** include `cloud_firestore` or `firebase_core` in its dependencies. All Firestore access is routed through the Express backend using the `firebase-admin` SDK (server-side, service account authenticated).

This means **Firestore Security Rules are not in the critical path** — the Admin SDK bypasses security rules by design. However:

> ⚠️ **If Firestore Security Rules are set to test mode** (`allow read, write: if true`), they won't affect the current app, but they would leave the database wide open to anyone who discovers the Firebase project ID (`music-vault-shanin` — visible in the committed `firebase-key.json`).

**Recommended Firestore Rules** (deploy via Firebase Console or `firebase deploy --only firestore:rules`):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Block ALL client-side access — all operations go through Admin SDK
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

This ensures that even if the project ID is known, no external client can directly read or modify data.

---

## 4. Summary & Prioritized Remediation Checklist

| Priority | Action | Effort |
|---|---|---|
| **P0 — NOW** | 🔴 Rotate Firebase service account key (V1) | 5 min |
| **P0 — NOW** | 🔴 Purge `firebase-key.json` from git history with BFG (V1) | 15 min |
| **P0 — NOW** | 🔴 Create scoped B2 Application Keys, retire master key (V2) | 20 min |
| **P1 — This Sprint** | 🟠 Reduce pre-signed URL TTL from 3600s to 900s (V3) | 2 min |
| **P1 — This Sprint** | 🟠 Add `isValidFileKey()` validation to stream & delete (V4) | 15 min |
| **P1 — This Sprint** | 🟡 Add `sanitizeSongForClient()` to all song endpoints (V5) | 20 min |
| **P2 — Cleanup** | 🟡 Remove stale Telegram credentials from `.env` and `render.yaml` (V6) | 5 min |
| **P2 — Cleanup** | Deploy restrictive Firestore Security Rules (`allow: if false`) | 5 min |
