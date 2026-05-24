# Sonic Vault — Android & Migration Guide

This document contains the necessary information to maintain your native Android app and migrate to Render once your Google Cloud credits expire.

---

## 📱 Android App Handover (Bubblewrap)

Your Android project has been generated in the `./android` directory using **Trusted Web Activity (TWA)**.

### 🔑 Signing Information
- **Keystore**: `android/android.keystore`
- **Alias**: `android`
- **Password**: `REPLACED_KEYSTORE_PASSWORD` (Store this securely!)

### 🛠️ How to Build/Update
1.  Open **Android Studio Panda**.
2.  Select **"Open an existing project"** and point it to the `d:\music\android` folder.
3.  To generate a new APK:
    -   In Android Studio, go to **Build > Build Bundle(s) / APK(s) > Build APK(s)**.
    -   Alternatively, run `bubblewrap build` from your terminal in the `android` folder (it will ask for the password above).
4.  **Sideloading**: Copy the `app-release-signed.apk` to your phone and install it.

---

## 🚀 Migration Guide to Render

When your Cloud Run credits expire, follow these steps to move to Render (Free Tier, No Credit Card needed).

### 1. 📂 Prepare your Code
- The code is already "host-agnostic."
- I've updated `backend/firebase.js` to load your Firebase key from an environment variable.

### 2. 🔑 Required Secrets (Checklist)
You will need to add these to the **Environment Variables** section in the Render dashboard:

| Variable | Value Source |
| :--- | :--- |
| `PORT` | `8080` |
| `TELEGRAM_API_ID` | From your `.env` |
| `TELEGRAM_API_HASH` | From your `.env` |
| `TELEGRAM_BOT_TOKEN` | From your `.env` |
| `TELEGRAM_CHANNEL_ID` | From your `.env` |
| `TELEGRAM_SESSION` | From your `.env` |
| `FIREBASE_KEY_JSON` | **CRITICAL**: Copy the *entire* content of `backend/firebase-key.json` and paste it here as a single string. |

### 3. 🌐 Update Asset Links
Once you have your new Render URL (e.g., `https://music-vault.onrender.com`):
1.  Go to `backend/public/manifest.json`.
2.  Update the `url` inside `related_applications` to point to `https://your-new-url.onrender.com/.well-known/assetlinks.json`.
3.  Re-deploy the Android app if you want to switch the native container to the new host.

---

## ✅ Final Verification
- **Web**: `https://music-vault-767870933282.asia-south1.run.app`
- **Android Trust**: `https://music-vault-767870933282.asia-south1.run.app/.well-known/assetlinks.json` (Should return your SHA256 fingerprint).
