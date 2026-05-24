# Render Migration Checklist

Follow these steps when your Google Cloud credits expire to move "Music Vault" to Render (CC-free tier).

## 1. 📂 Code Readiness
- The code is already "host-agnostic."
- `backend/firebase.js` is updated to load keys from environment variables.
- `Dockerfile` is verified for standard OCI runtimes.

## 2. 🔑 Required Secrets (Checklist)
Add these to the **Environment Variables** section in the Render dashboard:

| Variable | Value Source |
| :--- | :--- |
| `PORT` | `8080` |
| `TELEGRAM_API_ID` | From your `.env` |
| `TELEGRAM_API_HASH` | From your `.env` |
| `TELEGRAM_BOT_TOKEN` | From your `.env` |
| `TELEGRAM_CHANNEL_ID` | From your `.env` |
| `TELEGRAM_SESSION` | From your `.env` |
| `FIREBASE_KEY_JSON` | **CRITICAL**: Copy the *entire* content of `backend/firebase-key.json` and paste it here as a single string. |

## 3. 🌐 URL & Trust Update
Once you have your new Render URL (e.g., `https://music-vault.onrender.com`):

1.  **Server side**:
    - Update `backend/public/manifest.json`: change the `url` inside `related_applications` to point to `https://your-new-url.onrender.com/.well-known/assetlinks.json`.
2.  **Android side**:
    - Open the `android/` project in **Android Studio Panda 4**.
    - If you want the native app to point to the new URL, you must update the `host` in `android/twa-manifest.json` and re-run `bubblewrap update && bubblewrap build`.
3.  **Redeploy**: Push the code to GitHub/GitLab and link it to Render for automatic deployments.
