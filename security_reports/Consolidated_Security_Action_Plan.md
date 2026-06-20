# Consolidated Security Action Plan — Homelab Threat Model
**Project:** Mixtape / Mixtape  
**Threat Model:** Self-hosted, single-tenant, open-source template  
**Date:** June 18, 2026

---

## 🛑 DEFCON 1: Critical Fixes Applied to the Codebase

These are the only findings from the three audit reports that map to catastrophic outcomes under the homelab threat model.

---

### Fix 1: Argument Injection in `yt-dlp` — Remote Code Execution on Host Machine
**Source:** SAST Report V1 (CRITICAL)  
**Threat:** A crafted YouTube URL or a Spotify track title starting with `--` can inject arbitrary flags into `yt-dlp`. The `--exec` flag in particular allows executing **any shell command** on the host. Since this runs on the user's personal machine, this is full host compromise.

**Fix:** Add the `--` positional separator before the URL/query argument in both files. This is a **two-line change** — the most important security fix in the entire project.

**Files:** [downloader.js](file:///d:/music/backend/downloader.js) · [adder.js](file:///d:/music/backend/adder.js)

---

### Fix 2: Firebase Service Account Key Baked into Git History
**Source:** Cloud Report V1 (CRITICAL)  
**Threat:** Your personal `firebase-key.json` was committed in `20d1829` and still lives in git history. If this repo goes public (or is already public), **anyone can extract your Firebase Admin SDK key** and gain full read/write/delete access to your Firestore database.

**Fix:**
1. **Rotate the key NOW** — Firebase Console → Project Settings → Service Accounts → Generate New Private Key. Replace `backend/firebase-key.json` with the new one.
2. **Purge from git history:**
   ```bash
   # Option A: BFG Repo Cleaner (recommended)
   bfg --delete-files firebase-key.json
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force

   # Option B: git filter-repo
   git filter-repo --invert-paths --path backend/firebase-key.json --force
   git push --force
   ```
3. **Create a `.env.example`** template file so users know what to fill in, not a real key file.

---

### Fix 3: Dead Telegram Credentials Still in `.env` and `render.yaml`
**Source:** Cloud Report V6 (MEDIUM → upgraded to CRITICAL for open-source)  
**Threat:** The `.env` still contains live Telegram Bot Token, API ID, API Hash, and Channel ID from the pre-migration architecture. The `render.yaml` deployment manifest also declares `TELEGRAM_*` env vars. If a user forks and accidentally commits their `.env`, or if the render.yaml confuses them into setting credentials they don't need, it's unnecessary exposure.

**Fix:** 
- Strip all `TELEGRAM_*` lines from `.env` and `render.yaml`.
- Clean up the `.env` to only contain what the B2 architecture actually needs.
- Add a `.env.example` to the repo as the canonical template.

---

### Fix 4: Android Manifest Permits Cleartext HTTP Traffic
**Source:** Mobile Report V1 (CRITICAL → simple one-line fix)  
**Threat:** `android:usesCleartextTraffic="true"` allows the app to communicate over plain HTTP. On public Wi-Fi, all API traffic (song metadata, stream URLs, room states) can be intercepted or tampered with.

**Fix:** Flip to `false`. The backend URL is already `https://`.

**File:** [AndroidManifest.xml](file:///d:/music/flutter_app/android/app/src/main/AndroidManifest.xml)

---

## 🗑️ Accepted Risks (For README "Security Considerations" Section)

The following were flagged in the enterprise-grade audits but are **explicitly accepted** for this self-hosted deployment model:

| Original Finding | Why It's Accepted |
|---|---|
| **No API authentication on endpoints** (SAST V2, Mobile V2) | This is a single-tenant personal server. You are the only user. Adding auth middleware would require every self-hoster to generate and manage API keys — unnecessary friction for a private instance. If you expose your server to the internet, consider putting it behind a reverse proxy with basic auth (e.g., Caddy, nginx). |
| **No rate limiting on `/api/add-song`** (SAST V3) | You are the only person calling this endpoint. If you spam your own transcoding server, that's on you. |
| **Wildcard CORS** (SAST V5) | Restrictive CORS origins add configuration complexity with zero benefit for a single-tenant app. Your server only serves your own client. |
| **Listening Room IDOR / no `roomSecret`** (SAST V4, Mobile V6) | Room IDs are 5-character codes shared intentionally between friends. In a self-hosted context, the room feature is opt-in and the "attacker" would need to know your server URL and guess a live room code. This is acceptable for a casual listening feature. |
| **B2 master key (not scoped)** (Cloud V2) | Scoped keys are a defense-in-depth measure for multi-tenant environments. You own the entire bucket. A single key simplifies setup. |
| **Pre-signed URL TTL of 1 hour** (Cloud V3) | You're streaming to yourself. A shorter TTL means more frequent re-signing and potential playback interruptions on slow connections. 1 hour is fine. |
| **`fileKey` leaked in API responses** (Cloud V5) | The `fileKey` is just `{trackId}.m4a`. Knowing it doesn't help an attacker without your B2 credentials. No real information disclosure risk for a private server. |
| **Backend URL hardcoded in Dart** (Mobile V3) | Users building the Flutter app will change this to their own server URL. It's a configuration constant, not a secret. |
| **APK signed with debug keys** (Mobile V4) | Users building from source will use their own signing configuration. The template repo doesn't ship production signing keys — that's the user's responsibility. Document this in the build guide. |
| **Exported `AudioService`** (Mobile V5) | Required by the `audio_service` Flutter plugin for system media controls (notification, lock screen, Bluetooth). Adding a signature-level permission guard risks breaking media controls on many Android devices. |
| **`SharedPreferences` in plaintext** (Mobile V7) | Stores only song metadata (titles, artists) and liked song IDs. No secrets. This is standard Flutter practice for non-sensitive preferences. |
| **Verbose error messages** (SAST V6) | Useful for self-hosters debugging their own setup. Sanitized errors make troubleshooting harder with zero benefit when you're the only user. |
