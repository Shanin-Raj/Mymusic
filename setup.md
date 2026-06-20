# 🛠️ Mixtape Setup Guide

This guide will walk you through setting up the Mixtape mobile app and its companion backend. It covers cloud storage, database, authentication, backend deployment on Hugging Face Spaces, and running the Flutter app.

---

## 1. Firebase Setup (Database & Authentication)

Mixtape uses Google Cloud Firestore for metadata and Firebase Authentication to manage users and access to listening rooms.

1. **Create a Firebase Project:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. **Enable Firestore:**
   - Go to **Firestore Database** and click **Create Database**.
   - Start in Production mode (or Test mode if you prefer).
3. **Enable Authentication:**
   - Go to **Authentication** -> **Sign-in method**.
   - Enable **Email/Password** and **Google Sign-In**.
4. **Generate Service Account Key (For Backend):**
   - Go to **Project Settings** -> **Service Accounts**.
   - Click **Generate new private key**.
   - Save the `.json` file, rename it to `firebase-key.json`, and place it in the `backend/` directory of your cloned repo.
5. **Configure Android App (For Flutter):**
   - In Firebase Console, add an Android app. 
   - Download the `google-services.json` file and place it in `flutter_app/android/app/`.

---

## 2. Backblaze B2 Setup (Audio Storage)

Mixtape stores all transcoded `.m4a` audio files in a private Backblaze B2 bucket, served via presigned URLs.

1. Log in to [Backblaze](https://www.backblaze.com/).
2. Create a **Private Bucket** (e.g., `MixtapeCloud`).
3. Go to **App Keys** and generate a new Application Key.
4. Note down the following values for your backend environment:
   * **Endpoint URL** (e.g., `s3.us-east-005.backblazeb2.com` — *omit `https://`*)
   * **Key ID**
   * **Application Key**
   * **Bucket Name**
   * **Region** (e.g., `us-east-005`)

---

## 3. Spotify API Setup (Metadata Resolution)

To fetch album artwork and metadata for Spotify links:
1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Create a new application.
3. Note your **Client ID** and **Client Secret**.

---

## 4. Backend Deployment (Hugging Face Spaces)

We use Hugging Face Spaces to host the Node.js backend using Docker. This provides a generous free tier for bandwidth.

1. Create a new Space on [Hugging Face](https://huggingface.co/spaces) and select **Docker** as the SDK.
2. Push the cloned repository to your Hugging Face Space.
3. **Environment Configuration:** In your Space **Settings** -> **Variables and secrets**, add the following **Secrets**:
   - `B2_ENDPOINT`
   - `B2_KEY_ID`
   - `B2_APPLICATION_KEY`
   - `B2_BUCKET_NAME`
   - `B2_REGION`
   - `SPOTIFY_CLIENT_ID`
   - `SPOTIFY_CLIENT_SECRET`
   - `FIREBASE_KEY_JSON` *(Copy the entire raw JSON text of `firebase-key.json` and paste it here)*
4. The Space will automatically build the Dockerfile, exposing port `7860`.

---

## 5. Flutter App Configuration

1. Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. Navigate to the App directory:
   ```bash
   cd flutter_app
   flutter pub get
   ```
3. Open `flutter_app/lib/services/api_service.dart` and configure the `baseUrl` to point to your Hugging Face space:
   ```dart
   static String baseUrl = 'https://your-space-name.hf.space';
   ```
4. Build and run:
   ```bash
   flutter run
   ```

---

## 6. How to Add Songs Manually in Terminal

If you want to manually add songs to your Backblaze B2 storage and Firestore database from your local machine terminal without using the Flutter app:

1. **Install Dependencies:** Run `npm install` in the root directory of the project (where `package.json` is located):
   ```bash
   npm install
   ```
2. **Setup Local Configuration:**
   * Make sure your `backend/.env` file is populated with your Backblaze B2 and Spotify credentials.
   * Make sure `backend/firebase-key.json` is present.
3. **Run the Song Adder CLI:** Run the `manual_add.js` script inside the `backend/` folder:
   * **Option A: Interactive Mode**
     Simply run the script with no arguments:
     ```bash
     node backend/manual_add.js
     ```
     This will prompt you with a menu where you can choose to:
     * Paste a Spotify track/playlist or YouTube link.
     * Manually enter a Song Name and Artist Name.
   * **Option B: Quick Direct Add**
     Provide a Spotify or YouTube link directly as a command-line argument:
     ```bash
     node backend/manual_add.js "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT"
     ```

The script will download the audio using `yt-dlp`, transcode it to `.m4a` with `ffmpeg`, upload it directly to your Backblaze B2 bucket, and sync the song metadata to your Firestore database.

